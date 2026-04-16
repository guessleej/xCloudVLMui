"""
routers/reports.py — 維護報告 CRUD
"""
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.schemas import ReportCreate, ReportOut, VlmSessionCapture
from services.report_service import (
    create_report, list_reports, get_report,
    soft_delete_report, report_to_out,
)

router = APIRouter(prefix="/api/reports", tags=["reports"])


@router.get("/", response_model=list[ReportOut])
async def get_reports(
    limit:  int = 50,
    offset: int = 0,
    db:     AsyncSession = Depends(get_db),
):
    reports = await list_reports(db, limit=limit, offset=offset)
    return [report_to_out(r) for r in reports]


@router.post("/", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
async def create_new_report(
    data: ReportCreate,
    db:   AsyncSession = Depends(get_db),
):
    report = await create_report(db, data)
    return report_to_out(report)


@router.get("/{report_id}", response_model=ReportOut)
async def get_single_report(
    report_id: str,
    db:        AsyncSession = Depends(get_db),
):
    report = await get_report(db, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return report_to_out(report)


@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(
    report_id: str,
    db:        AsyncSession = Depends(get_db),
):
    ok = await soft_delete_report(db, report_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Report not found")


@router.get("/{report_id}/download")
async def download_report_md(
    report_id: str,
    db:        AsyncSession = Depends(get_db),
):
    """下載 Markdown 原始文字（前端也可直接使用 /reports/{id} 的 markdown_content）"""
    from fastapi.responses import PlainTextResponse
    report = await get_report(db, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    safe_title = "".join(c if c.isalnum() or c in "-_" else "_" for c in (report.title or "report"))
    return PlainTextResponse(
        content=report.markdown_content or "",
        media_type="text/markdown",
        headers={"Content-Disposition": f'attachment; filename="{safe_title}.md"'},
    )


@router.post("/capture-vlm-session", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
async def capture_vlm_session(
    payload: VlmSessionCapture,
    db:      AsyncSession = Depends(get_db),
):
    """
    VLM WebUI 巡檢結束後前端觸發。
    自動以 raw_vlm_json 產生 MD 報告並儲存至資料庫。
    """
    metadata = {
        "session_id": payload.session_id,
        "captured_at": payload.captured_at,
        "source": payload.source,
    }
    if payload.equipment_id:
        metadata["equipment_id"] = payload.equipment_id
    if payload.equipment_name:
        metadata["equipment_name"] = payload.equipment_name
    if payload.operator_note:
        metadata["operator_note"] = payload.operator_note

    raw_payload: dict | None = None
    markdown_content: str | None = None
    if payload.raw_vlm_json:
        raw_payload = {**payload.raw_vlm_json, "_capture_metadata": metadata}
    else:
        raw_payload = {"_capture_metadata": metadata, "_capture_status": "incomplete"}
        markdown_content = _incomplete_capture_markdown(metadata)

    data = ReportCreate(
        title=          f"VLM 巡檢報告 — {payload.captured_at[:16]}",
        equipment_id=   payload.equipment_id,
        equipment_name= payload.equipment_name,
        risk_level=     _infer_risk(payload.raw_vlm_json),
        source=         payload.source,
        raw_vlm_json=   raw_payload,
        markdown_content=markdown_content,
    )
    report = await create_report(db, data)
    return report_to_out(report)


def _infer_risk(vlm_json: dict | None) -> str:
    if not vlm_json:
        return "moderate"
    return (
        vlm_json.get("risk_level")
        or vlm_json.get("overall_risk_level")
        or "moderate"
    )


def _incomplete_capture_markdown(metadata: dict[str, str]) -> str:
    lines = [
        "# VLM 巡檢報告（資料不完整）",
        "",
        "此報告由半自動回寫建立，尚未附上 `raw_vlm_json`，請補登原始巡檢 JSON 以產生完整結構化內容。",
        "",
        "## 會話資訊",
        "",
        f"- Session ID：`{metadata.get('session_id', 'N/A')}`",
        f"- Captured At：`{metadata.get('captured_at', 'N/A')}`",
        f"- Source：`{metadata.get('source', 'vlm-webui')}`",
    ]
    if metadata.get("equipment_id"):
        lines.append(f"- Equipment ID：`{metadata['equipment_id']}`")
    if metadata.get("equipment_name"):
        lines.append(f"- Equipment Name：`{metadata['equipment_name']}`")
    if metadata.get("operator_note"):
        lines.extend(["", "## 操作員備註", "", metadata["operator_note"]])

    return "\n".join(lines)
