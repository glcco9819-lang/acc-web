import { redirect } from "next/navigation";

export default function Home() {
  /* v2.5.0 — ورود به میزکار چندپنجره‌ای (فهرست پنجره‌های باز در ساید بار پایین) */
  redirect("/desktop");
}
