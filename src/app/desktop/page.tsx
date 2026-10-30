import Workspace from "@/components/Workspace";

/* میزکار چندپنجره‌ای (v2.5.0) — منوی اصلی، نوار زمینه، پنجره‌های شناور MDI
   و ساید بار پایینِ پنجره‌های باز. پنجره‌ها همان صفحات /windows/* هستند که
   با ?embed=1 بدون قابِ منو/زمینه درون پنجره نمایش داده می‌شوند. */
export default function Page() {
  return <Workspace />;
}
