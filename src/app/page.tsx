export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col justify-center px-6 py-20">
      <div className="rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-primary">
          TourNTravels
        </p>
        <h1 className="font-heading mt-4 text-4xl font-bold text-slate-900">
          Travel journal foundation
        </h1>
        <p className="mt-4 max-w-xl text-base text-slate-600">
          This is the Milestone 02 application scaffold. Database and storage infrastructure are
          being configured here.
        </p>
      </div>
    </main>
  );
}
