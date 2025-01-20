"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState } from "react";

type User = {
  firstName: string;
  lastName: string;
  email: string;
  role: string;
};

export default function NavBar() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const verifyUser = async () => {
      try {
        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/verify`, {
          credentials: 'include'
        });
        
        if (response.ok) {
          const userData = await response.json();
          setUser(userData);
        }
      } catch (error) {
        console.error('Verification error:', error);
      }
    };

    verifyUser();
  }, []);

  const handleLogout = () => {
    document.cookie = 'token=; path=/; expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    window.location.href = '/login';
  };

  return (
    <nav className="bg-foreground text-background p-4">
      <div className="container mx-auto flex justify-between items-center">
        <Link href="/" className="text-xl font-bold flex items-center gap-2">
          <Image 
            src="/Lifter.png" 
            alt="GoLift Logo" 
            width={40} 
            height={40}
          />
          goLift
        </Link>
        
        <div className="flex gap-4 items-center">
          {user ? (
            <>
              <Link href="/dashboard" className="hover:text-gray-300">
                Dashboard
              </Link>
              <Link href="/programs" className="hover:text-gray-300">
                Programs
              </Link>
              <button 
                onClick={handleLogout}
                className="hover:text-gray-300"
              >
                Logout
              </button>
              <span>
                {user.firstName} {user.lastName}
              </span>
            </>
          ) : (
            <>
              <Link href="/login" className="hover:text-gray-300">
                Login
              </Link>
              <Link href="/register" className="hover:text-gray-300">
                Register
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
} 