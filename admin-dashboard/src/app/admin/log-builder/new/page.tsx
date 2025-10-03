'use client';

export default function NewTemplatePage() {
  return (
    <div className="min-h-screen bg-gray-900 text-white p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <a href="/admin/PROJ-001" className="text-blue-400 hover:text-blue-300 mb-4 inline-block">
            ← Back to Dashboard
          </a>
          <h1 className="text-3xl font-bold">Create New Template</h1>
          <p className="text-gray-400 mt-2">Design a new thermal log template for your operators</p>
        </div>

        <div className="bg-gray-800 border border-gray-700 rounded-lg p-6">
          <form className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Template Name
              </label>
              <input
                type="text"
                className="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:border-blue-500 focus:outline-none"
                placeholder="Enter template name..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Description
              </label>
              <textarea
                className="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:border-blue-500 focus:outline-none"
                rows={3}
                placeholder="Describe this template..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Template Type
              </label>
              <select className="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:border-blue-500 focus:outline-none">
                <option>Thermal Log</option>
                <option>Inspection Report</option>
                <option>Maintenance Log</option>
              </select>
            </div>

            <div className="flex gap-4 pt-4">
              <button
                type="submit"
                className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-md font-medium"
              >
                Create Template
              </button>
              <a
                href="/admin/PROJ-001"
                className="bg-gray-700 hover:bg-gray-600 text-white px-6 py-2 rounded-md font-medium inline-block"
              >
                Cancel
              </a>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}