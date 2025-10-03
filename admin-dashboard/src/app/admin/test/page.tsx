export default function TestPage() {
  return (
    <div className="min-h-screen bg-gray-900 text-white p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-8 text-center">
          Tailwind Test Page
        </h1>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <div className="w-12 h-12 bg-blue-500 rounded-lg mb-4"></div>
            <h2 className="text-xl font-semibold mb-2">Card 1</h2>
            <p className="text-gray-400">This is a test card with Tailwind styling</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <div className="w-12 h-12 bg-green-500 rounded-lg mb-4"></div>
            <h2 className="text-xl font-semibold mb-2">Card 2</h2>
            <p className="text-gray-400">Another test card with different colors</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <div className="w-12 h-12 bg-purple-500 rounded-lg mb-4"></div>
            <h2 className="text-xl font-semibold mb-2">Card 3</h2>
            <p className="text-gray-400">Third test card to verify grid layout</p>
          </div>
        </div>
        
        <div className="flex gap-4 justify-center">
          <button className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-medium transition-colors">
            Primary Button
          </button>
          <button className="bg-gray-700 hover:bg-gray-600 text-white px-6 py-3 rounded-lg font-medium transition-colors">
            Secondary Button
          </button>
        </div>
      </div>
    </div>
  );
}