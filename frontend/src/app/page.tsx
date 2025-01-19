"use client";

import Link from "next/link";
import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    const verifyAuth = async () => {
      try {
        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/verify`, {
          credentials: 'include'
        });
        
        if (response.ok) {
          router.push('/dashboard');
        }
      } catch (error) {
        console.error('Verification error:', error);
      }
    };

    verifyAuth();
  }, [router]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8">
      <main className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold mb-2">GoLift</h1>
          <p className="text-gray-600 dark:text-gray-400">
            Your personal strength training companion
          </p>
        </div>
        
        <div className="space-y-4">
          <Link 
            href="/login"
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-foreground hover:bg-opacity-90"
          >
            Login
          </Link>
          
          <Link
            href="/register" 
            className="w-full flex justify-center py-2 px-4 border border-foreground rounded-md shadow-sm text-sm font-medium text-foreground bg-transparent hover:bg-foreground hover:text-background"
          >
            Create Account
          </Link>
        </div>
      </main>
    </div>
  );
}
