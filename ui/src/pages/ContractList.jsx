import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { format } from 'date-fns'
import { contractApi } from '../services/api'
import Loading from '../components/Loading'
import ErrorMessage from '../components/ErrorMessage'
import ButtonSpinner from '../components/ButtonSpinner'

const ContractList = () => {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [statusFilter, setStatusFilter] = useState('ACT')
  const [deletingId, setDeletingId] = useState(null)

  const { data, isLoading, error } = useQuery({
    queryKey: ['contracts', statusFilter],
    queryFn: () => contractApi.getAll(statusFilter),
  })

  const deleteMutation = useMutation({
    mutationFn: (id) => contractApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['contracts'] })
      setDeletingId(null)
    },
    onError: () => {
      setDeletingId(null)
    }
  })

  const handleDelete = (contract) => {
    if (window.confirm(`Cloturer le contrat "${contract.CONT_REFERENCE}" ?`)) {
      setDeletingId(contract.CONT_ID)
      deleteMutation.mutate(contract.CONT_ID)
    }
  }

  const handleDeclareClaim = (contract) => {
    navigate(`/contracts/${contract.CONT_ID}/claim`, { state: { contract } })
  }

  const formatDate = (date) => {
    if (!date) return '-'
    try {
      return format(new Date(date), 'dd/MM/yyyy')
    } catch {
      return date
    }
  }

  if (isLoading) return <Loading message="Chargement des contrats..." />
  if (error) return <ErrorMessage message={error.message} code={error.code} />

  const contracts = data?.data || []

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Contrats</h1>
          <p className="mt-2 text-gray-600">
            Liste des contrats de protection juridique
          </p>
        </div>
        <div className="flex items-center space-x-4">
          <div>
            <label className="label">Statut</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input-field"
            >
              <option value="">Tous</option>
              <option value="ACT">Actif</option>
              <option value="SUS">Suspendu</option>
              <option value="EXP">Expiré</option>
              <option value="CLS">Clôturé</option>
            </select>
          </div>
        </div>
      </div>

      {/* Info Banner */}
      <div className="bg-green-50 border border-green-200 rounded-lg p-4">
        <p className="text-green-800 text-sm">
          <strong>Workflow Demo:</strong> Sélectionnez un contrat actif pour déclarer un sinistre.
          Le système validera automatiquement la couverture et la période d'attente.
        </p>
      </div>

      {/* Contracts Table */}
      <div className="card overflow-hidden p-0">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Référence
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Client
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Produit
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Période
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Prime
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Statut
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {contracts.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center text-gray-500">
                    Aucun contrat trouvé
                  </td>
                </tr>
              ) : (
                contracts.map((contract) => (
                  <tr key={contract.CONT_ID} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-das-blue">
                        {contract.CONT_REFERENCE}
                      </div>
                      <div className="text-xs text-gray-500">
                        Courtier: {contract.BROKER_CODE}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">
                        {contract.CUSTOMER_NAME}
                      </div>
                      <div className="text-xs text-gray-500">
                        {contract.CUST_TYPE === 'IND' ? 'Particulier' : 'Entreprise'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {contract.PRODUCT_NAME}
                      </div>
                      <div className="text-xs text-gray-500">
                        {contract.PRODUCT_CODE}
                      </div>
                      {contract.VEHICLES_COUNT > 0 && (
                        <div className="text-xs text-gray-500">
                          🚗 {contract.VEHICLES_COUNT} véhicule(s)
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <div>{formatDate(contract.START_DATE)}</div>
                      <div className="text-gray-500">au {formatDate(contract.END_DATE)}</div>
                      {contract.AUTO_RENEWAL === 'Y' && (
                        <span className="text-xs text-green-600">🔄 Auto-renewal</span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        €{parseFloat(contract.PREMIUM_AMT || 0).toFixed(2)}
                      </div>
                      <div className="text-xs text-gray-500">
                        {contract.PAY_FREQUENCY === 'M' && 'Mensuel'}
                        {contract.PAY_FREQUENCY === 'Q' && 'Trimestriel'}
                        {contract.PAY_FREQUENCY === 'A' && 'Annuel'}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {contract.STATUS === 'ACT' && (
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                          Actif
                        </span>
                      )}
                      {contract.STATUS === 'SUS' && (
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">
                          Suspendu
                        </span>
                      )}
                      {contract.STATUS === 'EXP' && (
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                          Expiré
                        </span>
                      )}
                      {contract.STATUS === 'CLS' && (
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">
                          Clôturé
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm space-x-2">
                      {contract.STATUS === 'ACT' && (
                        <>
                          <button
                            onClick={() => handleDeclareClaim(contract)}
                            className="btn-success text-sm"
                          >
                            Déclarer Sinistre
                          </button>
                          <button
                            onClick={() => handleDelete(contract)}
                            disabled={deletingId === contract.CONT_ID}
                            className="px-3 py-1 text-sm text-red-600 hover:text-red-800 hover:bg-red-50 rounded disabled:opacity-50 flex items-center gap-1"
                          >
                            {deletingId === contract.CONT_ID && <ButtonSpinner className="text-red-600" />}
                            {deletingId === contract.CONT_ID ? 'Cloture...' : 'Cloturer'}
                          </button>
                        </>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Stats Footer */}
      {contracts.length > 0 && (
        <div className="text-sm text-gray-600">
          Total: {contracts.length} contrat(s) affiché(s)
        </div>
      )}
    </div>
  )
}

export default ContractList
