import type { Metadata } from "next";
import { Inter, Fraunces } from "next/font/google";
import "./globals.css";
import { publicEnv } from "@/lib/env/public";

const inter = Inter({ subsets: ["latin"], variable: "--font-sans" });
const fraunces = Fraunces({ subsets: ["latin"], variable: "--font-heading" });

export const metadata: Metadata = {
  metadataBase: new URL(publicEnv.NEXT_PUBLIC_SITE_URL),
  title: {
    default: "TourNTravels",
    template: "%s | TourNTravels"
  },
  description: "A travel platform for packages, trips and car bookings.",
  openGraph: {
    title: "TourNTravels",
    description: "A travel platform for packages, trips and car bookings.",
    url: publicEnv.NEXT_PUBLIC_SITE_URL,
    siteName: "TourNTravels",
    locale: "en_IN"
  },
  themeColor: "#0F5C63"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${inter.variable} ${fraunces.variable}`}>
      <body>{children}</body>
    </html>
  );
}
