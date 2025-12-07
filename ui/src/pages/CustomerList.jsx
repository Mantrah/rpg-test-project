import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { customerApi } from '../services/api'

const CustomerList = () => {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data, isLoading, error } = useQuery({
    queryKey: ['customers'],
    queryFn: customerApi.list,
  })

  const deleteMutation = useMutation({
    mutationFn: customerApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries(['customers'])
    },
  })

  const handleDelete = (id, name) => {
    if (window.confirm(`Supprimer le client "${name}" ?`)) {
      deleteMutation.mutate(id)
    }
  }

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="text-gray-500">Chargement...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4">
        <h3 className="text-red-800 font-semibold">Erreur</h3>
        <p className="text-red-600">{error.message}</p>
        <p className="text-red-500 text-sm">Code: {error.code || 'UNKNOWN'}</p>
      </div>
    )
  }

  const customers = data?.data || []

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Clients</h1>
          <p className="mt-2 text-gray-600">
            {customers.length} client{customers.length !== 1 ? 's' : ''} enregistré{customers.length !== 1 ? 's' : ''}
          </p>
        </div>
        <button
          onClick={() => navigate('/customers/create')}
          className="btn-success"
        >
          + Nouveau Client
        </button>
      </div>

      {customers.length === 0 ? (
        <div className="card text-center py-12">
          <p className="text-gray-500 mb-4">Aucun client enregistré</p>
          <button
            onClick={() => navigate('/customers/create')}
            className="btn-primary"
          >
            Ajouter un client
          </button>
        </div>
      ) : (
        <div className="card overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Client
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Contact
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Ville
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Statut
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {customers.map((customer) => (
                <tr key={customer.CUST_ID} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-gray-900">
                      {customer.CUST_TYPE === 'IND'
                        ? `${customer.FIRST_NAME} ${customer.LAST_NAME}`
                        : customer.COMPANY_NAME}
                    </div>
                    {customer.CUST_TYPE === 'IND' && customer.NATIONAL_ID && (
                      <div className="text-sm text-gray-500">{customer.NATIONAL_ID}</div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      customer.CUST_TYPE === 'IND'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-purple-100 text-purple-800'
                    }`}>
                      {customer.CUST_TYPE === 'IND' ? 'Particulier' : 'Entreprise'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{customer.EMAIL}</div>
                    <div className="text-sm text-gray-500">{customer.PHONE}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {customer.CITY}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      customer.STATUS === 'ACT'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {customer.STATUS === 'ACT' ? 'Actif' : 'Inactif'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button
                      onClick={() => handleDelete(
                        customer.CUST_ID,
                        customer.CUST_TYPE === 'IND'
                          ? `${customer.FIRST_NAME} ${customer.LAST_NAME}`
                          : customer.COMPANY_NAME
                      )}
                      className="text-red-600 hover:text-red-900"
                    >
                      Supprimer
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export default CustomerList
