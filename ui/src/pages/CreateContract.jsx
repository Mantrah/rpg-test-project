import { useState, useEffect, useRef } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { customerApi, productApi, contractApi } from '../services/api'
import Loading from '../components/Loading'
import ErrorMessage from '../components/ErrorMessage'

// Frequency mapping: code -> {label, multiplier}
const FREQUENCY_INFO = {
  'A': { label: 'Annuel', multiplier: 1.00 },
  'Q': { label: 'Trimestriel', multiplier: 1.02 },
  'M': { label: 'Mensuel', multiplier: 1.05 },
}

const CreateContract = () => {
  const location = useLocation()
  const navigate = useNavigate()
  const broker = location.state?.broker

  const [step, setStep] = useState(1)
  const [formData, setFormData] = useState({
    customerId: null,
    productCode: '',
    vehiclesCount: 0,
    payFrequency: 'A',
    autoRenewal: 'Y',
    calculatedPremium: null,
  })

  const [errors, setErrors] = useState({})

  // Track latest premium request to ignore stale responses
  const latestPremiumRequestRef = useRef(0)

  // Fetch customers and products
  const { data: customers, isLoading: customersLoading } = useQuery({
    queryKey: ['customers'],
    queryFn: () => customerApi.getAll(),
  })

  const { data: products } = useQuery({
    queryKey: ['products'],
    queryFn: productApi.getAll,
  })

  // Premium calculation mutation
  const premiumMutation = useMutation({
    mutationFn: productApi.calculatePremium,
    onSuccess: (data) => {
      setFormData(prev => ({
        ...prev,
        calculatedPremium: data.data,
      }))
    },
  })

  // Contract creation mutation
  const createMutation = useMutation({
    mutationFn: contractApi.create,
    onSuccess: (data) => {
      alert(`Contrat cree avec succes!\n\nReference: ${data.data.contReference}`)
      navigate('/contracts')
    },
    onError: (error) => {
      alert(`Erreur: ${error.message}`)
    },
  })

  // Auto-calculate premium when product or vehicles change (with debounce and request tracking)
  useEffect(() => {
    if (!formData.productCode || step !== 2) return

    const timer = setTimeout(async () => {
      // Increment request ID and capture it for this request
      const requestId = ++latestPremiumRequestRef.current

      try {
        const result = await productApi.calculatePremium({
          productCode: formData.productCode,
          vehiclesCount: formData.vehiclesCount,
          payFrequency: formData.payFrequency,
        })

        // Only update state if this is still the latest request
        if (requestId === latestPremiumRequestRef.current) {
          setFormData(prev => ({
            ...prev,
            calculatedPremium: result.data,
          }))
        }
      } catch (error) {
        console.error('Premium calculation error:', error)
      }
    }, 300) // 300ms debounce

    return () => clearTimeout(timer)
  }, [formData.productCode, formData.vehiclesCount, formData.payFrequency, step])

  if (!broker) {
    return (
      <div className="space-y-6">
        <ErrorMessage message="Courtier non selectionne. Retournez a la liste des courtiers." />
        <button onClick={() => navigate('/brokers')} className="btn-primary">
          Retour aux Courtiers
        </button>
      </div>
    )
  }

  // Get selected customer details
  const selectedCustomer = customers?.data?.find(c => c.CUST_ID === formData.customerId)

  const validateStep1 = () => {
    const newErrors = {}
    if (!formData.customerId) {
      newErrors.customerId = 'Veuillez selectionner un client'
    }
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const validateStep2 = () => {
    const newErrors = {}
    if (!formData.productCode) newErrors.productCode = 'Produit requis'
    if (!formData.calculatedPremium) newErrors.premium = 'Attendre le calcul de la prime'
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleNext = () => {
    if (step === 1 && validateStep1()) {
      setStep(2)
    } else if (step === 2 && validateStep2()) {
      setStep(3)
    }
  }

  const handleSubmit = async () => {
    const startDate = new Date()
    const endDate = new Date()
    endDate.setFullYear(endDate.getFullYear() + 1)

    const contractData = {
      brokerId: broker.BROKER_ID,
      custId: formData.customerId,
      productCode: formData.productCode,
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      vehiclesCount: formData.vehiclesCount,
      totalPremium: formData.calculatedPremium?.totalPremium || 0,
      payFrequency: formData.payFrequency,
      autoRenewal: formData.autoRenewal,
      notes: `Contract created via demo UI for broker ${broker.BROKER_CODE}`,
    }

    createMutation.mutate(contractData)
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Creer un Contrat</h1>
        <p className="mt-2 text-gray-600">
          Courtier: <span className="font-medium text-das-blue">{broker.COMPANY_NAME}</span> ({broker.BROKER_CODE})
        </p>
      </div>

      {/* Progress Steps */}
      <div className="flex items-center justify-center space-x-4">
        <div className={`flex items-center ${step >= 1 ? 'text-das-blue' : 'text-gray-400'}`}>
          <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
            step >= 1 ? 'bg-das-blue text-white' : 'bg-gray-200'
          }`}>
            1
          </div>
          <span className="ml-2 font-medium">Client</span>
        </div>
        <div className="w-16 h-1 bg-gray-300"></div>
        <div className={`flex items-center ${step >= 2 ? 'text-das-blue' : 'text-gray-400'}`}>
          <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
            step >= 2 ? 'bg-das-blue text-white' : 'bg-gray-200'
          }`}>
            2
          </div>
          <span className="ml-2 font-medium">Produit</span>
        </div>
        <div className="w-16 h-1 bg-gray-300"></div>
        <div className={`flex items-center ${step >= 3 ? 'text-das-blue' : 'text-gray-400'}`}>
          <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
            step >= 3 ? 'bg-das-blue text-white' : 'bg-gray-200'
          }`}>
            3
          </div>
          <span className="ml-2 font-medium">Recapitulatif</span>
        </div>
      </div>

      {/* Step 1: Customer Selection */}
      {step === 1 && (
        <div className="card space-y-6">
          <h2 className="text-xl font-semibold text-gray-900">Etape 1: Selection du Client</h2>

          {customersLoading ? (
            <Loading message="Chargement des clients..." />
          ) : (
            <div>
              <label className="label">Selectionner un client *</label>
              <select
                value={formData.customerId || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, customerId: e.target.value ? parseInt(e.target.value) : null }))}
                className="input-field"
              >
                <option value="">-- Selectionner un client --</option>
                {customers?.data?.map(c => (
                  <option key={c.CUST_ID} value={c.CUST_ID}>
                    {c.CUST_TYPE === 'IND'
                      ? `${c.FIRST_NAME} ${c.LAST_NAME}`
                      : c.COMPANY_NAME
                    } ({c.EMAIL})
                  </option>
                ))}
              </select>
              {errors.customerId && <p className="text-red-600 text-sm mt-1">{errors.customerId}</p>}

              <p className="text-sm text-gray-500 mt-4">
                Pas de client dans la liste ? <button onClick={() => navigate('/customers/new')} className="text-das-blue underline">Creer un nouveau client</button>
              </p>
            </div>
          )}

          <div className="flex justify-end">
            <button onClick={handleNext} className="btn-primary" disabled={!formData.customerId}>
              Suivant
            </button>
          </div>
        </div>
      )}

      {/* Step 2: Product */}
      {step === 2 && (
        <div className="card space-y-6">
          <h2 className="text-xl font-semibold text-gray-900">Etape 2: Choix du Produit</h2>

          <div>
            <label className="label">Produit DAS *</label>
            <select
              value={formData.productCode}
              onChange={(e) => setFormData(prev => ({ ...prev, productCode: e.target.value }))}
              className="input-field"
            >
              <option value="">-- Selectionner --</option>
              {products?.data?.map(p => (
                <option key={p.PRODUCT_CODE} value={p.PRODUCT_CODE}>
                  {p.PRODUCT_NAME} - {parseFloat(p.BASE_PREMIUM || 0).toFixed(2)} EUR/an
                </option>
              ))}
            </select>
            {errors.productCode && <p className="text-red-600 text-sm mt-1">{errors.productCode}</p>}
          </div>

          <div>
            <label className="label">Nombre de Vehicules (+25 EUR par vehicule)</label>
            <input
              type="number"
              min="0"
              max="99"
              value={formData.vehiclesCount}
              onChange={(e) => setFormData(prev => ({ ...prev, vehiclesCount: parseInt(e.target.value) || 0 }))}
              className="input-field"
            />
          </div>

          <div>
            <label className="label">Frequence de Paiement</label>
            <select
              value={formData.payFrequency}
              onChange={(e) => setFormData(prev => ({ ...prev, payFrequency: e.target.value }))}
              className="input-field"
            >
              <option value="A">Annuel (pas de surcharge)</option>
              <option value="Q">Trimestriel (+2%)</option>
              <option value="M">Mensuel (+5%)</option>
            </select>
          </div>

          <div>
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={formData.autoRenewal === 'Y'}
                onChange={(e) => setFormData(prev => ({ ...prev, autoRenewal: e.target.checked ? 'Y' : 'N' }))}
                className="mr-2"
              />
              <span className="text-sm text-gray-700">Renouvellement automatique</span>
            </label>
          </div>

          {/* Premium Calculator Result */}
          {premiumMutation.isPending && <Loading message="Calcul de la prime..." />}

          {premiumMutation.isError && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <p className="text-red-700">Erreur lors du calcul de la prime. Veuillez reessayer.</p>
            </div>
          )}

          {formData.calculatedPremium && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
              <h3 className="font-semibold text-green-900 mb-3">Calcul de la Prime</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span>Prime de base:</span>
                  <span className="font-medium">{(formData.calculatedPremium.basePremium || 0).toFixed(2)} EUR</span>
                </div>
                {formData.vehiclesCount > 0 && (
                  <div className="flex justify-between">
                    <span>Addon vehicules ({formData.vehiclesCount} x 25 EUR):</span>
                    <span className="font-medium">{(formData.calculatedPremium.vehicleAddon || 0).toFixed(2)} EUR</span>
                  </div>
                )}
                {FREQUENCY_INFO[formData.payFrequency]?.multiplier > 1 && (
                  <div className="flex justify-between">
                    <span>Surcharge {FREQUENCY_INFO[formData.payFrequency]?.label} (+{((FREQUENCY_INFO[formData.payFrequency]?.multiplier - 1) * 100).toFixed(0)}%):</span>
                    <span className="font-medium">{(formData.calculatedPremium.frequencySurcharge || 0).toFixed(2)} EUR</span>
                  </div>
                )}
                <div className="border-t border-green-300 pt-2 flex justify-between text-lg font-bold text-green-900">
                  <span>TOTAL:</span>
                  <span>{(formData.calculatedPremium.totalPremium || 0).toFixed(2)} EUR</span>
                </div>
              </div>
            </div>
          )}

          <div className="flex justify-between">
            <button onClick={() => setStep(1)} className="btn-secondary">
              Retour
            </button>
            <button onClick={handleNext} className="btn-primary" disabled={!formData.calculatedPremium}>
              Suivant
            </button>
          </div>
        </div>
      )}

      {/* Step 3: Summary */}
      {step === 3 && (
        <div className="card space-y-6">
          <h2 className="text-xl font-semibold text-gray-900">Etape 3: Recapitulatif</h2>

          <div className="space-y-4">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Courtier</h3>
              <p className="text-sm text-gray-700">{broker.COMPANY_NAME} ({broker.BROKER_CODE})</p>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Client</h3>
              <p className="text-sm text-gray-700">
                {selectedCustomer ? (
                  selectedCustomer.CUST_TYPE === 'IND'
                    ? `${selectedCustomer.FIRST_NAME} ${selectedCustomer.LAST_NAME}`
                    : selectedCustomer.COMPANY_NAME
                ) : `Client ID: ${formData.customerId}`}
                {selectedCustomer?.EMAIL && ` - ${selectedCustomer.EMAIL}`}
              </p>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Produit</h3>
              <p className="text-sm text-gray-700">
                {formData.calculatedPremium?.productName || formData.productCode}
              </p>
              {formData.vehiclesCount > 0 && (
                <p className="text-sm text-gray-700">{formData.vehiclesCount} vehicule(s)</p>
              )}
            </div>

            <div className="bg-das-blue text-white p-4 rounded-lg">
              <h3 className="font-semibold mb-2">Prime Totale</h3>
              <p className="text-3xl font-bold">
                {(formData.calculatedPremium?.totalPremium || 0).toFixed(2)} EUR
              </p>
              <p className="text-sm mt-1">
                Paiement {FREQUENCY_INFO[formData.payFrequency]?.label.toLowerCase() || 'annuel'}
              </p>
            </div>
          </div>

          <div className="flex justify-between">
            <button onClick={() => setStep(2)} className="btn-secondary">
              Retour
            </button>
            <button
              onClick={handleSubmit}
              disabled={createMutation.isPending}
              className="btn-success"
            >
              {createMutation.isPending ? 'Creation...' : 'Creer le Contrat'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default CreateContract
