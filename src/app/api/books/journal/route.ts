import { NextRequest, NextResponse } from "next/server";
import { journal } from "../common";

/* دفتر روزنامه [روزنامه — خروجی چاپی قانونی] */
export async function GET(req: NextRequest) {
  const r = await journal(req);
  return NextResponse.json(r.body, { status: r.status });
}
