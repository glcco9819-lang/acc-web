"use client";

import { api, fa, STATE_FA } from "@/lib/ui";

/* ============================================================================
   مشاهدهٔ کامل یک سند (v2.2.0) — ردیف‌ها با «کد و عنوان» هر سطح
   کد کل/کد معین/کد تفصیلی ۴-۶ همگی صریح و قابل مشاهده‌اند (رفع باگ ①)
   v2.2.0: دکمهٔ «ویرایش سند» — درخواست کارفرما: ویرایش سند در همان پنجرهٔ مرور حساب‌ها
   زمان‌های ردپای عملیات شمسی هستند (API تبدیل می‌کند)
   v2.4.5 — اکشن‌های جدید ردپا: ۸ یادداشت، ۹ کپی سند + نمایش یادداشتِ هر رکورد
   ============================================================================ */

export interface VchDetail { hdr: any; items: any[]; log: any[]; reversalOf?: any }

export async function fetchVoucher(id: number): Promise<VchDetail> {
  return api(`/api/vch/get?id=${id}`);
}

const ACTION_FA = ["", "صدور", "بررسی", "لغو بررسی", "قطعی", "لغو قطعی", "برگشت", "ویرایش", "یادداشت", "کپی سند"];

export function VoucherDetailCard({ d, onClose, onEdit, canEdit }: { d: VchDetail; onClose?: () => void; onEdit?: () => void; canEdit?: boolean }) {
  const h = d.hdr;
  const editable = !!onEdit && (canEdit ?? true) && h.State !== 3 && !h.ReversalOf && String(h.SourceModule || "ACC") === "ACC";
  return (
    <div className="window" style={{ marginTop: 12 }}>
      <div className="window-title">
        <span>سند {fa(h.VchNo)} — {h.TypeTitle}{h.ReversalOf ? " (برگشتی)" : ""}</span>
        <span style={{ display: "inline-flex", gap: 6 }}>
          {editable && (
            <button className="btn" onClick={onEdit} style={{ padding: "1px 10px" }}
              title="ویرایش سند در همین پنجره [فرم: اصلاح سند]">ویرایش سند</button>
          )}
          {onClose && <button className="btn" onClick={onClose} style={{ padding: "1px 10px" }}>بستن</button>}
        </span>
      </div>
      <div className="window-body">
        <p style={{ marginBottom: 8, fontSize: 12.5 }}>
          عطف: <b>{fa(h.FolioNo)}</b> · ش فرعی: {fa(h.SubNo ?? 0)} · تاریخ: {h.VchDate} · شرح: {h.Descr || "—"}
          {h.LatinDescr ? <> · Latin: <span dir="ltr">{h.LatinDescr}</span></> : null}
          {" "}· وضعیت: <b>{STATE_FA[h.State]}</b>
          {" "}· سازنده: {h.CreatedBy}{h.CreatedAtFa ? <span className="muted"> ({h.CreatedAtFa})</span> : null}
          {" "}· بررسی: {h.CheckedBy || "—"}{h.CheckedAtFa ? <span className="muted"> ({h.CheckedAtFa})</span> : null}
          {" "}· قطعی: {h.FinalizedBy || "—"}{h.FinalizedAtFa ? <span className="muted"> ({h.FinalizedAtFa})</span> : null}
          {h.BranchId ? <> · شعبه: {h.BranchId}</> : null}
        </p>
        <table className="grid">
          <thead><tr>
            <th>#</th>
            <th>کد کل</th><th>شرح کل</th>
            <th>کد معین</th><th>شرح معین</th>
            <th>کد تفصیلی ۴</th><th>کد تفصیلی ۵</th><th>کد تفصیلی ۶</th>
            <th>شرح ردیف</th>
            <th className="num">بدهکار</th><th className="num">بستانکار</th>
          </tr></thead>
          <tbody>
            {d.items.map((it: any) => (
              <tr key={it.LineId}>
                <td>{it.RowNo}</td>
                <td className="ltr"><b>{it.KolCode}</b></td>
                <td>{it.KolTitle}</td>
                <td className="ltr"><b>{it.MoeinCode}</b></td>
                <td>{it.MoeinTitle}</td>
                <td>{it.Taf1Id ? <>{it.Taf1Code} — {it.Taf1Title}</> : "—"}</td>
                <td>{it.Taf2Id ? <>{it.Taf2Code} — {it.Taf2Title}</> : "—"}</td>
                <td>{it.Taf3Id ? <>{it.Taf3Code} — {it.Taf3Title}</> : "—"}</td>
                <td>{it.Descr || "—"}</td>
                <td className="num">{fa(it.Dbt)}</td>
                <td className="num">{fa(it.Crt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="muted" style={{ marginTop: 8 }}>
          ردپای عملیات: {d.log.map((l: any) => `${ACTION_FA[l.Action] || l.Action}${l.Note ? ` — ${l.Note}` : ""} (${l.ByUser} — ${l.AtFa})`).join(" ← ")}
        </p>
        {d.reversalOf && <p className="muted">برگشتِ سند شماره {fa(d.reversalOf.VchNo)} مورخ {d.reversalOf.VchDate}</p>}
      </div>
    </div>
  );
}
