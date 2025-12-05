import { Link, Outlet, useLocation } from 'react-router-dom'
import clsx from 'clsx'

const Layout = () => {
  const location = useLocation()

  const navItems = [
    { path: '/', label: 'Dashboard', icon: '📊' },
    { path: '/brokers', label: 'Courtiers', icon: '🏢' },
    { path: '/contracts', label: 'Contrats', icon: '📄' },
  ]

  const isActive = (path) => {
    if (path === '/') return location.pathname === '/'
    return location.pathname.startsWith(path)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-das-blue text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <div className="text-3xl">⚖️</div>
              <div>
                <h1 className="text-2xl font-bold">DAS Belgium</h1>
                <p className="text-sm text-blue-200">Protection Juridique</p>
              </div>
            </div>
            <div className="text-sm text-blue-200">
              Demo System • IBM i Backend
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            {navItems.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                className={clsx(
                  'flex items-center space-x-2 py-4 px-2 border-b-2 font-medium text-sm transition-colors',
                  isActive(item.path)
                    ? 'border-das-blue text-das-blue'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                )}
              >
                <span>{item.icon}</span>
                <span>{item.label}</span>
              </Link>
            ))}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Outlet />
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="text-center text-sm text-gray-500">
            <p>DAS Belgium Backend Demo • RPG ILE Service Programs on IBM i V7R5</p>
            <p className="mt-1">
              <span className="text-green-600 font-medium">✓ TELEBIB2 Compliant</span> •
              <span className="text-green-600 font-medium ml-2">✓ 79% Amicable Resolution</span> •
              <span className="text-green-600 font-medium ml-2">✓ €350 Threshold</span>
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default Layout
