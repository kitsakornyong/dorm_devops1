import { Filter } from 'lucide-react';

interface FilterBarProps {
    selectedBuilding: string;
    setSelectedBuilding: (v: string) => void;
    startDate: string;
    setStartDate: (v: string) => void;
    endDate: string;
    setEndDate: (v: string) => void;
    buildingsList: { id: number; name_building: string }[];
}

export default function DashboardFilterBar({
    selectedBuilding, setSelectedBuilding,
    startDate, setStartDate,
    endDate, setEndDate,
    buildingsList
}: FilterBarProps) {
    return (
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 flex flex-wrap gap-4 items-center">
            <div className="flex items-center gap-2 text-slate-500 font-bold mr-2">
                <Filter size={18} />
                <span>Filters:</span>
            </div>
            
            <select 
                value={selectedBuilding} 
                onChange={e => setSelectedBuilding(e.target.value)}
                className="bg-slate-50 border border-slate-200 text-slate-700 rounded-lg px-3 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-shadow"
            >
                <option value="All">All Buildings</option>
                {buildingsList.map(b => (
                    <option key={b.id} value={b.id.toString()}>{b.name_building}</option>
                ))}
            </select>

            <div className="flex items-center gap-2">
                <span className="text-sm text-slate-500 font-medium">From</span>
                <input 
                    type="date"
                    value={startDate}
                    onChange={e => setStartDate(e.target.value)}
                    className="bg-slate-50 border border-slate-200 text-slate-700 rounded-lg px-3 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-shadow"
                />
            </div>
            
            <div className="flex items-center gap-2">
                <span className="text-sm text-slate-500 font-medium">To</span>
                <input 
                    type="date"
                    value={endDate}
                    onChange={e => setEndDate(e.target.value)}
                    className="bg-slate-50 border border-slate-200 text-slate-700 rounded-lg px-3 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-shadow"
                />
            </div>
            
            <button 
                onClick={() => { setStartDate(''); setEndDate(''); }}
                className="text-xs text-indigo-600 hover:text-indigo-800 font-bold ml-auto"
            >
                Clear Dates
            </button>
        </div>
    );
}
