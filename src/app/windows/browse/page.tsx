"use client";

import { useCallback, useEffect, useState } from "react";
import Shell from "@/components/Shell";
import { api, fa } from "@/lib/ui";

/* [فرم اصلی: مرور حساب‌ها — acvwdf] درخت حساب‌ها + کارت گردش معین با مانده در خط + فیلتر تفصیلی */
export default function Page() {
  const [tree, setTree] = useState<any[]>([]);
  const [err, setErr] = useState("");
  const [sel, setSel] = useState<string>("");
  const [card, setCard] = useState<any | null>(null);
  const [dlId, setDlId] = useState("");
  const [from, setFrom] = useState(""); const [to, setTo] = useState("");
  const [dls, setDls] = useState<any[]>([]);
  const [moeins, setMoeins] = useState<any[]>([]);

  const loadTree = useCallback(async () => {
    try { const j = await api("/api/browse?mode=tree"); setTree(j.rows || []); }
    catch (e: any) { setErr(e.message); }
  }, []);
  useEffect(() => { loadTree(); api("/api/acc/dl").then((j) => setDls(j.rows || [])).catch(() => {}); api("/api/acc/moein").then((j) => setMoeins(j.rows || [])).catch(() => {}); }, [loadTree]);

  const openCard = async (moein: string, d = dlId) => {
    setSel(moein);
    try {
      const p = new URLSearchParams({ mode: "card", moein }); if (d) p.set("dlId", d); if (from) p.set("from", from); if (to) p.set("to", to);
      setCard(await api(`/api/browse?${p}`));
    } catch (e: any) { setErr(e.message); }
  };

  const selM = moeins.find((m) => m.Code === sel);
  const groups = new Map<string, any[]>();
  tree.forEach((r) => { const k = `${r.GroupCode}|${r.GroupTitle}`; if (!groups.has(k)) groups.set(k, []); groups.get(k)!.push(r); });

  return (
    <Shell title="مرور حساب‌ها" sub="درخت کدینگ + کارت گردش با مانده در خط">
      {err && <div className="msg err">{err}</div>}
      <div style={{ display: "grid", gridTemplateColumns: "1.1fr 1.6fr", gap: 12 }}>
        <div className="scrollbox" style={{ maxHeight: "70vh" }}>
          <div className="tree" style={{ padding: 8 }}>
            {[...groups.entries()].map(([gk, items]) => {
              const [gc, gt] = gk.split("|");
              const kols = new Map<string, any[]>();
              items.forEach((r) => { if (r.KolCode) { const k = `${r.KolCode}|${r.KolTitle}`; if (!kols.has(k)) kols.set(k, []); kols.get(k)!.push(r); } });
              return (
                <div key={gk}>
                  <div className="lv1">گروه {gc} — {gt}</div>
                  {[...kols.entries()].map(([kk, ms]) => {
                    const [kc, kt] = kk.split("|");
                    return (
                      <div className="lv2" key={kk}>
                        کل {kc} — {kt}
                        {ms.filter((m) => m.MoeinCode).map((m) => (
                          <div className="lv3" key={m.MoeinCode}
                            style={{ cursor: "pointer", background: sel === m.MoeinCode ? "#dfeaf3" : undefined }}
                            onClick={() => openCard(m.MoeinCode)}>
                            {m.MoeinCode} — {m.MoeinTitle}
                            <span className="dl"> {m.Dl1TypeId ? `· ${m.Dl1Title}` : ""}</span>
                          </div>
                        ))}
                      </div>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </div>

        <div>
          {sel && (
            <div className="form-grid" style={{ gridTemplateColumns: "1fr 130px 130px auto" }}>
              <div className="field"><label>فیلتر تفصیلی{selM?.Dl1TypeId ? "" : " (این معین تفصیلی ندارد)"}</label>
                <select value={dlId} disabled={!selM?.Dl1TypeId} onChange={(e) => { setDlId(e.target.value); openCard(sel, e.target.value); }}>
                  <option value="">همه</option>
                  {dls.filter((d) => d.DlTypeId === selM?.Dl1TypeId).map((d) => <option key={d.DlId} value={d.DlId}>{d.Code} — {d.Title}</option>)}
                </select>
              </div>
              <div className="field"><label>از تاریخ</label><input value={from} onChange={(e) => setFrom(e.target.value)} style={{ direction: "ltr" }} /></div>
              <div className="field"><label>تا تاریخ</label><input value={to} onChange={(e) => setTo(e.target.value)} style={{ direction: "ltr" }} /></div>
              <div className="field"><label>&nbsp;</label><button className="btn" onClick={() => openCard(sel)}>نمایش</button></div>
            </div>
          )}
          {card && (
            <>
              <p style={{ margin: "6px 0" }}>
                <b>کارت {card.head.Code} — {card.head.Title}</b>
                <span className="muted"> (کل: {card.head.KolTitle})</span>
                {" "}· مانده ابتدا: <b>{fa(card.opening)}</b>
              </p>
              <div className="scrollbox">
                <table className="grid">
                  <thead><tr>
                    <th>تاریخ</th><th>سند</th><th>شرح</th>
                    {card.head.Dl1TypeId && <th>تفصیلی</th>}
                    <th className="num">بدهکار</th><th className="num">بستانکار</th><th className="num">مانده</th>
                  </tr></thead>
                  <tbody>
                    {card.rows.map((r: any, i: number) => (
                      <tr key={`${r.HdrId}-${r.RowNo}-${i}`}>
                        <td className="num">{r.VchDate}</td>
                        <td className="num">{fa(r.VchNo)}{r.ReversalOf ? <span className="badge src" style={{ marginInlineStart: 3 }}>برگشتی</span> : null}</td>
                        <td>{r.ItmDescr || r.VchDescr}</td>
                        {card.head.Dl1TypeId && <td>{r.Dl1Title || r.Dl2Title || r.Dl3Title || "—"}</td>}
                        <td className="num">{fa(r.Dbt)}</td><td className="num">{fa(r.Crt)}</td>
                        <td className="num"><b>{fa(r.Balance)}</b></td>
                      </tr>
                    ))}
                    {!card.rows.length && <tr><td colSpan={card.head.Dl1TypeId ? 7 : 6} className="muted" style={{ textAlign: "center", padding: 14 }}>گردشی در این بازه نیست</td></tr>}
                  </tbody>
                </table>
              </div>
              <div className="totalbar">
                <span>مانده پایان: {fa(card.rows.length ? card.rows[card.rows.length - 1].Balance : card.opening)}</span>
              </div>
            </>
          )}
        </div>
      </div>
    </Shell>
  );
}
