// src/components/landing/Background.js
export default function Background() {
  return (
    <div
      aria-hidden
      className="pointer-events-none absolute inset-0 -z-10 overflow-hidden bg-gradient-to-br from-sky-50 via-blue-100 to-blue-300"
    >
      <div className="absolute -right-40 -top-48 h-[700px] w-[700px] rounded-full bg-blue-400/40" />
      <div className="absolute right-[5%] top-[25%] h-[650px] w-[650px] rounded-full bg-sky-300/40" />
      <div className="absolute -left-[15%] top-[40%] h-[900px] w-[900px] rounded-full bg-blue-500/30" />
      <div className="absolute left-[30%] -top-40 h-[500px] w-[500px] rounded-full bg-white/30" />
      <div className="absolute left-[8%] top-[6%] h-72 w-72 rounded-full border border-white/50" />
      <div className="absolute right-[15%] bottom-[10%] h-96 w-96 rounded-full border border-white/40" />
    </div>
  );
}
