import { useState, useEffect } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { format } from 'date-fns'
import { productApi, claimApi } from '../services/api'
import Loading from '../components/Loading'
import ErrorMessage from '../components/ErrorMessage'

const DeclareClaim = () => {
  const { id } = useParams()
  const location = useLocation()
  const navigate = useNavigate()
  const contract = location.state?.contract

  const [formData, setFormData] = useState({
    guaranteeCode: '',
    circumstanceCode: 'LITIGE',
    declarationDate: new Date().toISOString().split('T')[0],
    incidentDate: '',
    description: '',
    claimedAmount: '',
  })

  const [validation, setValidation] = useState(null)
  const [validationErrors, setValidationErrors] = useState([])
  const [validationWarnings, setValidationWarnings] = useState([])

  // Fetch guarantees for the contract's product
  const { data: guarantees, isLoading: loadingGuarantees } = useQuery({
    queryKey: ['guarantees', contract?.PRODUCT_ID],
    queryFn: () => productApi.getGuarantees(contract?.PRODUCT_ID),
    enabled: !!contract?.PRODUCT_ID,
  })

  // Validation mutation (real-time)
  const validateMutation = useMutation({
    mutationFn: claimApi.validate,
    onSuccess: (data) => {
      setValidation(data.data)
      setValidationErrors(data.data.errors || [])
      setValidationWarnings(data.data.warnings || [])
    },
  })

  // Create claim mutation
  const createMutation = useMutation({
    mutationFn: claimApi.create,
    onSuccess: (data) => {
      alert(
        `✅ Sinistre créé avec succès!\n\n` +
        `Référence: ${data.data.claimReference}\n` +
        `Dossier: ${data.data.fileReference}`
      )
      navigate('/contracts')
    },
    onError: (error) => {
      alert(`❌ Erreur: ${error.message}`)
    },
  })

  // Auto-validate when relevant fields change
  useEffect(() => {
    if (
      contract &&
      formData.guaranteeCode &&
      formData.claimedAmount &&
      parseFloat(formData.claimedAmount) > 0 &&
      formData.incidentDate
    ) {
      validateMutation.mutate({
        contId: contract.CONT_ID,
        guaranteeCode: formData.guaranteeCode,
        claimedAmount: parseFloat(formData.claimedAmount),
        incidentDate: formData.incidentDate,
      })
    } else {
      setValidation(null)
      setValidationErrors([])
      setValidationWarnings([])
    }
  }, [formData.guaranteeCode, formData.claimedAmount, formData.incidentDate])

  if (!contract) {
    return (
      <div className="space-y-6">
        <ErrorMessage message="Contrat non sélectionné. Retournez à la liste des contrats." />
        <button onClick={() => navigate('/contracts')} className="btn-primary">
          Retour aux Contrats
        </button>
      </div>
    )
  }

  const handleSubmit = (e) => {
    e.preventDefault()

    if (!validation || !validation.isValid) {
      alert('Veuillez corriger les erreurs de validation avant de soumettre.')
      return
    }

    const claimData = {
      contId: contract.CONT_ID,
      guaranteeCode: formData.guaranteeCode,
      circumstanceCode: formData.circumstanceCode,
      declarationDate: formData.declarationDate,
      incidentDate: formData.incidentDate,
      description: formData.description,
      claimedAmount: parseFloat(formData.claimedAmount),
    }

    createMutation.mutate(claimData)
  }

  const formatDate = (date) => {
    if (!date) return '-'
    try {
      return format(new Date(date), 'dd/MM/yyyy')
    } catch {
      return date
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Déclarer un Sinistre</h1>
        <p className="mt-2 text-gray-600">
          Contrat: <span className="font-medium text-das-blue">{contract.CONT_REFERENCE}</span>
        </p>
      </div>

      {/* Contract Info */}
      <div className="card">
        <h3 className="font-semibold text-gray-900 mb-3">Informations Contrat</h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span className="text-gray-600">Client:</span>
            <span className="ml-2 font-medium">{contract.CUSTOMER_NAME}</span>
          </div>
          <div>
            <span className="text-gray-600">Produit:</span>
            <span className="ml-2 font-medium">{contract.PRODUCT_NAME}</span>
          </div>
          <div>
            <span className="text-gray-600">Période:</span>
            <span className="ml-2 font-medium">
              {formatDate(contract.START_DATE)} - {formatDate(contract.END_DATE)}
            </span>
          </div>
          <div>
            <span className="text-gray-600">Statut:</span>
            <span className="ml-2 font-medium">
              {contract.STATUS === 'ACT' ? '✓ Actif' : contract.STATUS}
            </span>
          </div>
        </div>
      </div>

      {/* Claim Form */}
      <form onSubmit={handleSubmit} className="card space-y-6">
        <h3 className="text-xl font-semibold text-gray-900">Déclaration de Sinistre</h3>

        {loadingGuarantees ? (
          <Loading message="Chargement des garanties..." />
        ) : (
          <>
            <div>
              <label className="label">Garantie *</label>
              <select
                value={formData.guaranteeCode}
                onChange={(e) => setFormData(prev => ({ ...prev, guaranteeCode: e.target.value }))}
                className="input-field"
                required
              >
                <option value="">-- Sélectionner une garantie --</option>
                {guarantees?.data?.map(g => (
                  <option key={g.GUARANTEE_CODE} value={g.GUARANTEE_CODE}>
                    {g.GUARANTEE_NAME} ({g.GUARANTEE_CODE})
                    {g.WAITING_MONTHS > 0 && ` - Période d'attente: ${g.WAITING_MONTHS} mois`}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="label">Circonstance *</label>
              <select
                value={formData.circumstanceCode}
                onChange={(e) => setFormData(prev => ({ ...prev, circumstanceCode: e.target.value }))}
                className="input-field"
                required
              >
                <option value="LITIGE">Litige</option>
                <option value="ACCIDENT">Accident</option>
                <option value="CONFLIT">Conflit</option>
                <option value="AUTRE">Autre</option>
              </select>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Date de Déclaration *</label>
                <input
                  type="date"
                  value={formData.declarationDate}
                  onChange={(e) => setFormData(prev => ({ ...prev, declarationDate: e.target.value }))}
                  className="input-field"
                  required
                />
              </div>
              <div>
                <label className="label">Date de l'Incident *</label>
                <input
                  type="date"
                  value={formData.incidentDate}
                  onChange={(e) => setFormData(prev => ({ ...prev, incidentDate: e.target.value }))}
                  className="input-field"
                  max={new Date().toISOString().split('T')[0]}
                  required
                />
              </div>
            </div>

            <div>
              <label className="label">Description *</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                className="input-field"
                rows="4"
                placeholder="Décrivez les circonstances du sinistre..."
                required
              />
            </div>

            <div>
              <label className="label">Montant Réclamé (€) *</label>
              <input
                type="number"
                step="0.01"
                min="0"
                value={formData.claimedAmount}
                onChange={(e) => setFormData(prev => ({ ...prev, claimedAmount: e.target.value }))}
                className="input-field"
                placeholder="0.00"
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                Seuil minimum DAS: €350
              </p>
            </div>

            {/* Real-time Validation Display */}
            {validateMutation.isLoading && (
              <div className="flex items-center space-x-2 text-blue-600">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>
                <span className="text-sm">Validation en cours...</span>
              </div>
            )}

            {/* Validation Errors */}
            {validationErrors.length > 0 && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <h4 className="font-semibold text-red-900 mb-2">⚠️ Erreurs de Validation</h4>
                <ul className="space-y-1 text-sm text-red-800">
                  {validationErrors.map((error, idx) => (
                    <li key={idx}>
                      • {error.message} <span className="text-xs text-red-600">({error.code})</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Validation Warnings */}
            {validationWarnings.length > 0 && (
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                <h4 className="font-semibold text-yellow-900 mb-2">⚠️ Avertissements</h4>
                <ul className="space-y-1 text-sm text-yellow-800">
                  {validationWarnings.map((warning, idx) => (
                    <li key={idx}>
                      • {warning.message} <span className="text-xs text-yellow-600">({warning.code})</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Validation Success */}
            {validation && validation.isValid && validationErrors.length === 0 && (
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <h4 className="font-semibold text-green-900 mb-3">✓ Validation Réussie</h4>
                {validation.coverage && (
                  <div className="space-y-2 text-sm text-green-800">
                    <div className="flex items-center space-x-2">
                      <span className="text-green-600 text-xl">✓</span>
                      <span>Garantie <strong>{validation.coverage.guaranteeName}</strong> couverte</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="text-green-600 text-xl">✓</span>
                      <span>
                        Période d'attente: {validation.coverage.waitingMonths} mois
                        (fin: {formatDate(validation.coverage.waitingEndDate)})
                      </span>
                    </div>
                    {validation.coverage.isWaitingPeriodOver ? (
                      <div className="flex items-center space-x-2">
                        <span className="text-green-600 text-xl">✓</span>
                        <span className="font-medium">Période d'attente écoulée - Couverture active</span>
                      </div>
                    ) : (
                      <div className="flex items-center space-x-2">
                        <span className="text-yellow-600 text-xl">⏳</span>
                        <span>
                          Couverture dans {validation.coverage.daysUntilCoverage} jours
                        </span>
                      </div>
                    )}
                    <div className="flex items-center space-x-2">
                      <span className="text-green-600 text-xl">✓</span>
                      <span>
                        Montant ≥ €350 (seuil DAS)
                      </span>
                    </div>
                    <div className="mt-3 pt-3 border-t border-green-300">
                      <p className="text-xs text-green-700">
                        <strong>Contrat:</strong> {validation.coverage.contractReference}<br/>
                        <strong>Produit:</strong> {validation.coverage.productName}<br/>
                        <strong>Début contrat:</strong> {formatDate(validation.coverage.contractStartDate)}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Business Rules Info */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <h4 className="font-semibold text-blue-900 mb-2">ℹ️ Règles Business DAS</h4>
              <ul className="text-sm text-blue-800 space-y-1">
                <li>• <strong>Seuil minimum:</strong> €350 (BUS006)</li>
                <li>• <strong>Plafond:</strong> €200,000 max</li>
                <li>• <strong>Période d'attente:</strong> Selon garantie (3-12 mois)</li>
                <li>• <strong>Objectif DAS:</strong> 79% résolution amiable</li>
              </ul>
            </div>

            {/* Submit Buttons */}
            <div className="flex justify-between">
              <button
                type="button"
                onClick={() => navigate('/contracts')}
                className="btn-secondary"
              >
                Annuler
              </button>
              <button
                type="submit"
                disabled={
                  createMutation.isLoading ||
                  !validation ||
                  !validation.isValid ||
                  validationErrors.length > 0
                }
                className="btn-success disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {createMutation.isLoading ? 'Création...' : '✓ Déclarer le Sinistre'}
              </button>
            </div>
          </>
        )}
      </form>
    </div>
  )
}

export default DeclareClaim
