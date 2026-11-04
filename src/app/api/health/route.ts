import { NextResponse } from "next/server";
import { publicEnv } from "@/lib/env/public";

export async function GET() {
  return NextResponse.json(
    {
      status: "ok",
      timestamp: new Date().toISOString(),
      businessTimezone: publicEnv.NEXT_PUBLIC_BUSINESS_TIMEZONE
    },
    {
      headers: {
        "Cache-Control": "no-store"
      }
    }
  );
}
