import { useQuery } from '@tanstack/react-query'
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'
import { dashboardApi } from '../services/api'
import Loading from '../components/Loading'
import ErrorMessage from '../components/ErrorMessage'
import KPICard from '../components/KPICard'

const Dashboard = () => {
  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['dashboardStats'],
    queryFn: dashboardApi.getStats,
  })

  const { data: claimsByStatus } = useQuery({
    queryKey: ['claimsByStatus'],
    queryFn: dashboardApi.getClaimsByStatus,
  })

  if (isLoading) return <Loading message="Chargement du dashboard..." />
  if (error) return <ErrorMessage message={error.message} code={error.code} />

  // Extract data with defaults for missing properties
  const brokers = stats.data?.brokers || { total: 0, active: 0 }
  const customers = {
    total: stats.data?.customers?.total || 0,
    active: stats.data?.customers?.active || 0,
    individual: stats.data?.customers?.individual || 0,
    business: stats.data?.customers?.business || 0
  }
  const contracts = {
    total: stats.data?.contracts?.total || 0,
    active: stats.data?.contracts?.active || 0,
    autoRenewal: stats.data?.contracts?.autoRenewal || 0
  }
  const claims = {
    total: stats.data?.claims?.total || 0,
    new: stats.data?.claims?.new || 0,
    underReview: stats.data?.claims?.underReview || 0,
    approved: stats.data?.claims?.approved || 0,
    rejected: stats.data?.claims?.rejected || 0,
    closed: stats.data?.claims?.closed || 0,
    amicableResolutions: stats.data?.claims?.amicableResolutions || 0,
    tribunalResolutions: stats.data?.claims?.tribunalResolutions || 0,
    amicableRate: stats.data?.claims?.amicableRate || 0,
    amicableRateTarget: stats.data?.claims?.amicableRateTarget || 79,
    totalClaimed: stats.data?.claims?.totalClaimed || 0,
    totalApproved: stats.data?.claims?.totalApproved || 0
  }

  // Format data for pie chart
  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8']
  const pieData = claimsByStatus?.data?.map(item => ({
    name: item.STATUS || item.label || 'Unknown',
    value: item.COUNT || item.count || 0
  })) || []

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">
          Vue d'ensemble du système de protection juridique DAS Belgium
        </p>
      </div>

      {/* KPIs Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <KPICard
          title="Courtiers Actifs"
          value={brokers.active}
          icon="🏢"
          color="blue"
          subtitle={`${brokers.total} total`}
        />
        <KPICard
          title="Clients Actifs"
          value={customers.active}
          icon="👥"
          color="green"
          subtitle={`${customers.individual} IND • ${customers.business} BUS`}
        />
        <KPICard
          title="Contrats Actifs"
          value={contracts.active}
          icon="📄"
          color="purple"
          subtitle={`${contracts.autoRenewal} auto-renewal`}
        />
        <KPICard
          title="Sinistres Total"
          value={claims.total}
          icon="⚖️"
          color="yellow"
          subtitle={`${claims.new} nouveaux`}
        />
      </div>

      {/* Secondary KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Résolution Amiable
          </h3>
          <div className="flex items-baseline space-x-2">
            <span className="text-4xl font-bold text-green-600">
              {claims.amicableRate}%
            </span>
            <span className="text-sm text-gray-500">
              (Objectif: {claims.amicableRateTarget}%)
            </span>
          </div>
          <div className="mt-4 text-sm text-gray-600">
            <p>{claims.amicableResolutions} amiables • {claims.tribunalResolutions} tribunaux</p>
          </div>
          {claims.amicableRate >= claims.amicableRateTarget ? (
            <p className="mt-2 text-sm text-green-600 font-medium">
              ✓ Objectif atteint !
            </p>
          ) : (
            <p className="mt-2 text-sm text-yellow-600 font-medium">
              ⚠ En dessous de l'objectif
            </p>
          )}
        </div>

        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Montants Sinistres
          </h3>
          <div className="space-y-3">
            <div>
              <p className="text-sm text-gray-600">Total réclamé</p>
              <p className="text-2xl font-bold text-gray-900">
                €{claims.totalClaimed.toLocaleString('fr-BE', { minimumFractionDigits: 2 })}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Total approuvé</p>
              <p className="text-2xl font-bold text-green-600">
                €{claims.totalApproved.toLocaleString('fr-BE', { minimumFractionDigits: 2 })}
              </p>
            </div>
          </div>
        </div>

        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Statuts Sinistres
          </h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Nouveaux</span>
              <span className="font-medium text-blue-600">{claims.new}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">En révision</span>
              <span className="font-medium text-yellow-600">{claims.underReview}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Approuvés</span>
              <span className="font-medium text-green-600">{claims.approved}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Rejetés</span>
              <span className="font-medium text-red-600">{claims.rejected}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Clôturés</span>
              <span className="font-medium text-gray-600">{claims.closed}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Pie Chart */}
      {pieData.length > 0 && (
        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Répartition des Sinistres par Statut
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {pieData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Info Footer */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <div className="flex items-start">
          <div className="text-blue-500 text-2xl mr-3">ℹ️</div>
          <div>
            <h4 className="text-blue-900 font-medium">Règles Business DAS Belgium</h4>
            <div className="mt-2 text-sm text-blue-800 space-y-1">
              <p>• <strong>Seuil minimum:</strong> €350 (BUS006 - MIN_CLAIM_THRESHOLD)</p>
              <p>• <strong>Plafond couverture:</strong> €200,000 max</p>
              <p>• <strong>Période d'attente:</strong> 3-12 mois selon garantie</p>
              <p>• <strong>Objectif résolution amiable:</strong> 79%</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Dashboard
