"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface ProgramData {
    name: string;
    description: string;
    daysPerWeek: number;
    numberOfWorkouts: number;
    programType: 'template' | 'custom';
}

export default function CreateProgram() {
    const router = useRouter();
    const [formData, setFormData] = useState<ProgramData>({
        name: '',
        description: '',
        daysPerWeek: 3,
        numberOfWorkouts: 1,
        programType: 'template'
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        
        try {
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/programs`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData),
                credentials: 'include'
            });

            if (!response.ok) {
                throw new Error('Failed to create program');
            }

            router.push('/dashboard');
        } catch (error) {
            console.error(error);
        }
    };

    return (
        <div className="min-h-screen p-8">
            <div className="max-w-2xl mx-auto">
                <h1 className="text-2xl font-bold mb-6">Create New Program</h1>
                
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="block mb-1">Program Name</label>
                        <input
                            type="text"
                            value={formData.name}
                            onChange={(e) => setFormData({...formData, name: e.target.value})}
                            className="w-full p-2 border rounded bg-background"
                            required
                        />
                    </div>

                    <div>
                        <label className="block mb-1">Description</label>
                        <textarea
                            value={formData.description}
                            onChange={(e) => setFormData({...formData, description: e.target.value})}
                            className="w-full p-2 border rounded bg-background"
                            rows={4}
                        />
                    </div>

                    <div>
                        <label className="block mb-1">Days per Week</label>
                        <input
                            type="number"
                            min="1"
                            max="7"
                            value={formData.daysPerWeek}
                            onChange={(e) => setFormData({...formData, daysPerWeek: parseInt(e.target.value)})}
                            className="w-full p-2 border rounded bg-background"
                            required
                        />
                    </div>

                    <div>
                        <label className="block mb-1">Number of Workouts</label>
                        <input
                            type="number"
                            min="1"
                            value={formData.numberOfWorkouts}
                            onChange={(e) => setFormData({...formData, numberOfWorkouts: parseInt(e.target.value)})}
                            className="w-full p-2 border rounded bg-background"
                            required
                        />
                    </div>

                    <div>
                        <label className="block mb-1">Program Type</label>
                        <select
                            value={formData.programType}
                            onChange={(e) => setFormData({...formData, programType: e.target.value as 'template' | 'custom'})}
                            className="w-full p-2 border rounded bg-background"
                        >
                            <option value="template">Template</option>
                            <option value="custom">Custom</option>
                        </select>
                    </div>

                    <button 
                        type="submit"
                        className="w-full bg-foreground text-background p-2 rounded hover:bg-opacity-90"
                    >
                        Create Program
                    </button>
                </form>
            </div>
        </div>
    );
} 