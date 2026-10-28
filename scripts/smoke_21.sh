#!/usr/bin/env bash
# smoke_21.sh — تست دود v2.1.0 روی بیلد تولیدی + دیتابیس مشتری (فقط خواندن + یک اعلامیهٔ آزمایشی که حذف می‌شود)
set -u
cd /home/z/my-project/acc-web
PORT=3211
LOG=/home/z/my-project/scripts/smoke21.log

echo "== stop old ==" ; pkill -f "standalone/server.js" 2>/dev/null; sleep 1

echo "== start standalone server =="
PORT=$PORT AUTO_UPDATE=off DB_HOST=85.133.175.190 DB_PORT=1433 DB_NAME=acc DB_USER=acc_app DB_PASS='Acc!2026$Web#p7Km' \
  node .next/standalone/server.js > "$LOG" 2>&1 &
SRV=$!
for i in $(seq 1 30); do
  sleep 1
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 3 "http://127.0.0.1:$PORT/" || true)
  [ "$code" != "" ] && [ "$code" != "000" ] && { echo "server up (HTTP $code) after ${i}s"; break; }
done

JAR=/home/z/my-project/scripts/smoke21.cookies
rm -f "$JAR"
echo "== login =="
curl -s -c "$JAR" -X POST "http://127.0.0.1:$PORT/api/auth/login" \
  -H "Content-Type: application/json" -d '{"username":"admin","password":"1234"}' | head -c 200; echo

CTX='%7B%22companyId%22%3A1%2C%22yearId%22%3A1%7D'
B="http://127.0.0.1:$PORT"
call() { local p="$1"; shift; curl -s -b "$JAR" -H "Cookie: acc_ctx=$CTX" "$@" "$B$p"; }

echo "== 1) tree =="
call "/api/review?mode=tree" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('ok:',j.get('ok'),'openDone:',j.get('openDone'))
print('groups:',len(j.get('groups',[])),'kols:',len(j.get('kols',[])),'moeins:',len(j.get('moeins',[])))
for m in j.get('moeins',[])[:5]:
    print('  moein',m['MoeinCode'],m['MoeinTitle'][:20],'D=',m['D'],'C=',m['C'],'Fx' if m.get('IsFx') else '')
g=[x for x in j.get('groups',[])]
print('sum D=',sum(x['D'] for x in g),'C=',sum(x['C'] for x in g))
"
echo "== 2) card full =="
call "/api/review?mode=card&level=moein&code=010101&display=full&runBal=1" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('ok:',j.get('ok'),'err:',j.get('error'))
if j.get('ok'):
    print('head:',j['head']['Code'],j['head']['Title'][:24],'nature',j['head']['AccNature'])
    print('rows:',len(j['rows']),'opening D/C:',j['opening'])
    print('totals:',j['totals'],'last balance:',j['rows'][-1]['Balance'] if j['rows'] else '-')
    print('first row keys ok:', all(k in (j['rows'][0] if j['rows'] else {}) for k in ('KolCode','MoeinCode','Taf1Code','Dbt','Crt','Balance','VoucherId')))
"
echo "== 3) card sumIn / sumNo =="
for d in sumIn sumNo; do
  call "/api/review?mode=card&level=moein&code=010101&display=$d" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('$d ok:',j.get('ok'),'rows:',len(j.get('rows',[])),'totals:',j.get('totals'))
"
done
echo "== 4) card dir=d =="
call "/api/review?mode=card&level=moein&code=010101&dir=d" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('dir=d ok:',j.get('ok'),'rows:',len(j.get('rows',[])),'all Dbt>0:',all(r['Dbt']>0 for r in j.get('rows',[])))
"
echo "== 5) filters year/month/no/vchType/kind =="
call "/api/review?mode=card&level=moein&code=010101&yFrom=1405&yTo=1405&mFrom=1&mTo=12&kind=normal" | python3 -c "
import json,sys
j=json.load(sys.stdin); print('filters ok:',j.get('ok'),'rows:',len(j.get('rows',[])))
"
echo "== 6) balance =="
call "/api/review?mode=balance&level=moein&code=010101" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('balance ok:',j.get('ok'),'err:',j.get('error'))
if j.get('ok'):
    print('till:',j['till'],'during:',j['during'],'after:',j['after'],'ob:',j['opening'])
    print('balD:',j['balD'],'balC:',j['balC'])
"
echo "== 7) analys =="
call "/api/review?mode=analys&level=moein&code=010101&group=1&analysed=all" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('analys ok:',j.get('ok'),'err:',j.get('error'),'rows:',len(j.get('rows',[])))
for r in j.get('rows',[])[:4]: print('  ',r['MoeinCode'],r.get('TafCode'),r['D'],r['C'])
"
echo "== 8) fx (moein با قلم ارزی) =="
FMOEIN=$(python3 -c "
import pymssql
c = pymssql.connect(server='85.133.175.190', port=1433, user='acc_app', password='Acc!2026\$Web#p7Km', database='acc', charset='UTF-8', login_timeout=15, timeout=30, autocommit=True)
cur = c.cursor()
cur.execute(\"SELECT TOP 1 i.MoeinCode FROM ACC.AccVoucherItm i WHERE i.FxId IS NOT NULL ORDER BY i.LineId DESC\")
r = cur.fetchall()
print(r[0][0] if r else '')
c.close()")
echo "fx moein: $FMOEIN"
if [ -n "$FMOEIN" ]; then
  call "/api/review?mode=fx&code=$FMOEIN" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('fx ok:',j.get('ok'),'err:',j.get('error'),'rows:',len(j.get('rows',[])))
for r in j.get('rows',[])[:4]: print('  ',r['FxCode'],r['FxD'],r['FxC'],'bal',r['FxBalance'])
"
  call "/api/review?mode=fxbal&code=$FMOEIN" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('fxbal ok:',j.get('ok'),'rows:',len(j.get('rows',[])))
"
fi

echo "== 9) note create/list/detail/delete =="
LINE=$(call "/api/review?mode=card&level=moein&code=010101&display=full" | python3 -c "
import json,sys
j=json.load(sys.stdin)
r=j['rows'][0]
print(r['VoucherId'],r['LineId'])" 2>/dev/null)
if [ -n "$LINE" ]; then
  VID=$(echo $LINE | cut -d' ' -f1); LID=$(echo $LINE | cut -d' ' -f2)
  echo "test line: voucher=$VID line=$LID"
  RES=$(call "/api/note" -X POST -H "Content-Type: application/json" -d "{\"noteDate\":\"1405/07/29\",\"title\":\"تست اعلامیه — حذف خواهد شد\",\"moeinCode\":\"010101\",\"items\":[{\"voucherId\":$VID,\"lineId\":$LID}]}")
  echo "create: $RES"
  NID=$(echo "$RES" | python3 -c "import json,sys; print(json.load(sys.stdin).get('noteId',''))")
  call "/api/note?id=$NID" | python3 -c "
import json,sys
j=json.load(sys.stdin)
print('detail ok:',j.get('ok'),'no:',j['hdr']['NoteNo'],'items:',len(j['items']),'first:',j['items'][0]['VchNo'] if j['items'] else '-')
"
  call "/api/note?id=$NID" -X DELETE > /dev/null
  echo "after delete:"; call "/api/note?id=$NID" | head -c 120; echo
else
  echo "no card rows for moein 1101 — note test skipped"
fi

echo "== 10) pages render =="
for p in review notes browse; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" "http://127.0.0.1:$PORT/windows/$p")
  echo "/windows/$p -> $code"
done

echo "== server log tail (migrate lines) =="
grep -E "\[migrate\]" "$LOG" | head -8

kill $SRV 2>/dev/null
echo "== done =="
