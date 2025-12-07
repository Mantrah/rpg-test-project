import { useState, useEffect } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { customerApi, productApi, contractApi, bceApi } from '../services/api'
import Loading from '../components/Loading'
import ErrorMessage from '../components/ErrorMessage'

const CreateContract = () => {
  const location = useLocation()
  const navigate = useNavigate()
  const broker = location.state?.broker

  const [step, setStep] = useState(1)
  const [formData, setFormData] = useState({
    // Step 1: Customer
    customerId: null,
    customerType: 'IND',
    firstName: '',
    lastName: '',
    companyName: '',
    vatNumber: '',
    naceCode: '',
    email: '',
    phone: '',
    street: '',
    houseNbr: '',
    boxNbr: '',
    postalCode: '',
    city: '',
    countryCode: 'BE',
    language: 'FR',

    // Step 2: Product
    productCode: '',
    vehiclesCount: 0,
    payFrequency: 'A',
    autoRenewal: 'Y',

    // Calculated
    calculatedPremium: null,
  })

  const [errors, setErrors] = useState({})
  const [bceSearching, setBceSearching] = useState(false)
  const [bceError, setBceError] = useState(null)

  // Fetch customers and products
  const { data: customers } = useQuery({
    queryKey: ['customers'],
    queryFn: () => customerApi.getAll('ACT'),
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
      alert(`✅ Contrat créé avec succès!\n\nRéférence: ${data.data.contReference}`)
      navigate('/contracts')
    },
    onError: (error) => {
      alert(`❌ Erreur: ${error.message}`)
    },
  })

  // BCE search function
  const handleBceSearch = async () => {
    if (!formData.vatNumber || formData.vatNumber.length < 10) {
      setBceError('Entrez un numéro de TVA valide (ex: BE0123456789)')
      return
    }

    setBceSearching(true)
    setBceError(null)

    try {
      const result = await bceApi.searchByVat(formData.vatNumber)
      const company = result.data

      // Auto-fill form with BCE data
      setFormData(prev => ({
        ...prev,
        companyName: company.companyName || prev.companyName,
        vatNumber: company.vatNumber || prev.vatNumber,
        naceCode: company.naceCode || prev.naceCode,
        street: company.address?.street || prev.street,
        houseNbr: company.address?.houseNbr || prev.houseNbr,
        boxNbr: company.address?.boxNbr || prev.boxNbr,
        postalCode: company.address?.postalCode || prev.postalCode,
        city: company.address?.city || prev.city,
        countryCode: company.address?.countryCode || 'BE',
      }))
    } catch (error) {
      setBceError(error.message || 'Entreprise non trouvée dans la BCE')
    } finally {
      setBceSearching(false)
    }
  }

  // Auto-calculate premium when product or vehicles change
  useEffect(() => {
    if (formData.productCode && step === 2) {
      premiumMutation.mutate({
        productCode: formData.productCode,
        vehiclesCount: formData.vehiclesCount,
        payFrequency: formData.payFrequency,
      })
    }
  }, [formData.productCode, formData.vehiclesCount, formData.payFrequency, step])

  if (!broker) {
    return (
      <div className="space-y-6">
        <ErrorMessage message="Courtier non sélectionné. Retournez à la liste des courtiers." />
        <button onClick={() => navigate('/brokers')} className="btn-primary">
          Retour aux Courtiers
        </button>
      </div>
    )
  }

  const validateStep1 = () => {
    const newErrors = {}

    if (!formData.customerId) {
      if (formData.customerType === 'IND') {
        if (!formData.firstName) newErrors.firstName = 'Prénom requis'
        if (!formData.lastName) newErrors.lastName = 'Nom requis'
      } else {
        if (!formData.companyName) newErrors.companyName = 'Nom de société requis'
      }
      if (!formData.email) newErrors.email = 'Email requis'
      if (!formData.street) newErrors.street = 'Rue requise'
      if (!formData.houseNbr) newErrors.houseNbr = 'Numéro requis'
      if (!formData.postalCode) newErrors.postalCode = 'Code postal requis'
      if (!formData.city) newErrors.city = 'Ville requise'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const validateStep2 = () => {
    const newErrors = {}
    if (!formData.productCode) newErrors.productCode = 'Produit requis'
    if (!formData.calculatedPremium) newErrors.premium = 'Calculer la prime d\'abord'
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
    // Create customer if needed
    let custId = formData.customerId

    if (!custId) {
      const customerData = {
        custType: formData.customerType,
        firstName: formData.firstName || null,
        lastName: formData.lastName || null,
        companyName: formData.companyName || null,
        vatNumber: formData.vatNumber || null,
        naceCode: formData.naceCode || null,
        email: formData.email,
        phone: formData.phone || null,
        street: formData.street,
        houseNbr: formData.houseNbr,
        boxNbr: formData.boxNbr || null,
        postalCode: formData.postalCode,
        city: formData.city,
        countryCode: formData.countryCode,
        language: formData.language,
      }

      try {
        const result = await customerApi.create(customerData)
        custId = result.data.custId
      } catch (error) {
        alert(`Erreur création client: ${error.message}`)
        return
      }
    }

    // Calculate contract dates
    const startDate = new Date()
    const endDate = new Date()
    endDate.setFullYear(endDate.getFullYear() + 1)

    const contractData = {
      brokerId: broker.BROKER_ID,
      custId: custId,
      productCode: formData.productCode,
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      vehiclesCount: formData.vehiclesCount,
      totalPremium: formData.calculatedPremium.finalPremium,
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
        <h1 className="text-3xl font-bold text-gray-900">Créer un Contrat</h1>
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
          <span className="ml-2 font-medium">Récapitulatif</span>
        </div>
      </div>

      {/* Step 1: Customer */}
      {step === 1 && (
        <div className="card space-y-6">
          <h2 className="text-xl font-semibold text-gray-900">Étape 1: Sélection Client</h2>

          {/* Existing Customer */}
          <div>
            <label className="label">Client Existant</label>
            <select
              value={formData.customerId || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, customerId: e.target.value ? parseInt(e.target.value) : null }))}
              className="input-field"
            >
              <option value="">-- Nouveau Client --</option>
              {customers?.data?.map(c => (
                <option key={c.CUST_ID} value={c.CUST_ID}>
                  {c.CUST_TYPE === 'IND'
                    ? `${c.FIRST_NAME} ${c.LAST_NAME}`
                    : c.COMPANY_NAME
                  } ({c.EMAIL})
                </option>
              ))}
            </select>
          </div>

          {/* New Customer Form */}
          {!formData.customerId && (
            <>
              <div>
                <label className="label">Type Client</label>
                <div className="flex space-x-4">
                  <label className="flex items-center">
                    <input
                      type="radio"
                      value="IND"
                      checked={formData.customerType === 'IND'}
                      onChange={(e) => setFormData(prev => ({ ...prev, customerType: e.target.value }))}
                      className="mr-2"
                    />
                    Particulier (IND)
                  </label>
                  <label className="flex items-center">
                    <input
                      type="radio"
                      value="BUS"
                      checked={formData.customerType === 'BUS'}
                      onChange={(e) => setFormData(prev => ({ ...prev, customerType: e.target.value }))}
                      className="mr-2"
                    />
                    Entreprise (BUS)
                  </label>
                </div>
              </div>

              {formData.customerType === 'IND' ? (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="label">Prénom *</label>
                    <input
                      type="text"
                      value={formData.firstName}
                      onChange={(e) => setFormData(prev => ({ ...prev, firstName: e.target.value }))}
                      className="input-field"
                    />
                    {errors.firstName && <p className="text-red-600 text-sm mt-1">{errors.firstName}</p>}
                  </div>
                  <div>
                    <label className="label">Nom *</label>
                    <input
                      type="text"
                      value={formData.lastName}
                      onChange={(e) => setFormData(prev => ({ ...prev, lastName: e.target.value }))}
                      className="input-field"
                    />
                    {errors.lastName && <p className="text-red-600 text-sm mt-1">{errors.lastName}</p>}
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  {/* BCE Search */}
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <label className="label text-blue-900">Recherche BCE (Banque-Carrefour des Entreprises)</label>
                    <div className="flex gap-2">
                      <input
                        type="text"
                        placeholder="N° TVA (ex: BE0123456789)"
                        value={formData.vatNumber}
                        onChange={(e) => setFormData(prev => ({ ...prev, vatNumber: e.target.value.toUpperCase() }))}
                        className="input-field flex-1"
                      />
                      <button
                        type="button"
                        onClick={handleBceSearch}
                        disabled={bceSearching}
                        className="btn-primary whitespace-nowrap"
                      >
                        {bceSearching ? 'Recherche...' : 'Rechercher'}
                      </button>
                    </div>
                    {bceError && <p className="text-red-600 text-sm mt-2">{bceError}</p>}
                    <p className="text-xs text-blue-700 mt-2">
                      Entrez le numéro de TVA pour auto-remplir les données de l'entreprise
                    </p>
                  </div>

                  <div>
                    <label className="label">Nom Société *</label>
                    <input
                      type="text"
                      value={formData.companyName}
                      onChange={(e) => setFormData(prev => ({ ...prev, companyName: e.target.value }))}
                      className="input-field"
                    />
                    {errors.companyName && <p className="text-red-600 text-sm mt-1">{errors.companyName}</p>}
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="label">N° TVA</label>
                      <input
                        type="text"
                        value={formData.vatNumber}
                        onChange={(e) => setFormData(prev => ({ ...prev, vatNumber: e.target.value.toUpperCase() }))}
                        className="input-field bg-gray-50"
                        readOnly
                      />
                    </div>
                    <div>
                      <label className="label">Code NACE</label>
                      <input
                        type="text"
                        value={formData.naceCode}
                        onChange={(e) => setFormData(prev => ({ ...prev, naceCode: e.target.value }))}
                        className="input-field bg-gray-50"
                        placeholder="ex: 62010"
                      />
                    </div>
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="label">Email *</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                    className="input-field"
                  />
                  {errors.email && <p className="text-red-600 text-sm mt-1">{errors.email}</p>}
                </div>
                <div>
                  <label className="label">Téléphone</label>
                  <input
                    type="text"
                    value={formData.phone}
                    onChange={(e) => setFormData(prev => ({ ...prev, phone: e.target.value }))}
                    className="input-field"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="col-span-2">
                  <label className="label">Rue *</label>
                  <input
                    type="text"
                    value={formData.street}
                    onChange={(e) => setFormData(prev => ({ ...prev, street: e.target.value }))}
                    className="input-field"
                  />
                  {errors.street && <p className="text-red-600 text-sm mt-1">{errors.street}</p>}
                </div>
                <div>
                  <label className="label">Numéro *</label>
                  <input
                    type="text"
                    value={formData.houseNbr}
                    onChange={(e) => setFormData(prev => ({ ...prev, houseNbr: e.target.value }))}
                    className="input-field"
                  />
                  {errors.houseNbr && <p className="text-red-600 text-sm mt-1">{errors.houseNbr}</p>}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="label">Boîte</label>
                  <input
                    type="text"
                    value={formData.boxNbr}
                    onChange={(e) => setFormData(prev => ({ ...prev, boxNbr: e.target.value }))}
                    className="input-field"
                  />
                </div>
                <div>
                  <label className="label">Code Postal *</label>
                  <input
                    type="text"
                    value={formData.postalCode}
                    onChange={(e) => setFormData(prev => ({ ...prev, postalCode: e.target.value }))}
                    className="input-field"
                  />
                  {errors.postalCode && <p className="text-red-600 text-sm mt-1">{errors.postalCode}</p>}
                </div>
                <div>
                  <label className="label">Ville *</label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => setFormData(prev => ({ ...prev, city: e.target.value }))}
                    className="input-field"
                  />
                  {errors.city && <p className="text-red-600 text-sm mt-1">{errors.city}</p>}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="label">Pays</label>
                  <select
                    value={formData.countryCode}
                    onChange={(e) => setFormData(prev => ({ ...prev, countryCode: e.target.value }))}
                    className="input-field"
                  >
                    <option value="BE">Belgique</option>
                    <option value="FR">France</option>
                    <option value="NL">Pays-Bas</option>
                    <option value="LU">Luxembourg</option>
                  </select>
                </div>
                <div>
                  <label className="label">Langue</label>
                  <select
                    value={formData.language}
                    onChange={(e) => setFormData(prev => ({ ...prev, language: e.target.value }))}
                    className="input-field"
                  >
                    <option value="FR">Français</option>
                    <option value="NL">Nederlands</option>
                    <option value="EN">English</option>
                  </select>
                </div>
              </div>
            </>
          )}

          <div className="flex justify-end">
            <button onClick={handleNext} className="btn-primary">
              Suivant →
            </button>
          </div>
        </div>
      )}

      {/* Step 2: Product */}
      {step === 2 && (
        <div className="card space-y-6">
          <h2 className="text-xl font-semibold text-gray-900">Étape 2: Choix du Produit</h2>

          <div>
            <label className="label">Produit DAS *</label>
            <select
              value={formData.productCode}
              onChange={(e) => setFormData(prev => ({ ...prev, productCode: e.target.value }))}
              className="input-field"
            >
              <option value="">-- Sélectionner --</option>
              {products?.data?.map(p => (
                <option key={p.PRODUCT_CODE} value={p.PRODUCT_CODE}>
                  {p.PRODUCT_NAME} - €{parseFloat(p.BASE_PREMIUM).toFixed(2)}/an
                </option>
              ))}
            </select>
            {errors.productCode && <p className="text-red-600 text-sm mt-1">{errors.productCode}</p>}
          </div>

          <div>
            <label className="label">Nombre de Véhicules (+€25 par véhicule)</label>
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
            <label className="label">Fréquence de Paiement</label>
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
          {premiumMutation.isLoading && <Loading message="Calcul de la prime..." />}

          {formData.calculatedPremium && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
              <h3 className="font-semibold text-green-900 mb-3">Calcul de la Prime</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span>Prime de base:</span>
                  <span className="font-medium">€{formData.calculatedPremium.basePremium.toFixed(2)}</span>
                </div>
                {formData.calculatedPremium.vehiclesCount > 0 && (
                  <div className="flex justify-between">
                    <span>Addon véhicules ({formData.calculatedPremium.vehiclesCount} × €25):</span>
                    <span className="font-medium">€{formData.calculatedPremium.vehicleAddon.toFixed(2)}</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span>Fréquence {formData.calculatedPremium.frequencyLabel} (×{formData.calculatedPremium.frequencyMultiplier}):</span>
                  <span className="font-medium">
                    {formData.calculatedPremium.frequencyMultiplier > 1 ? '+' : ''}
                    {((formData.calculatedPremium.frequencyMultiplier - 1) * 100).toFixed(0)}%
                  </span>
                </div>
                <div className="border-t border-green-300 pt-2 flex justify-between text-lg font-bold text-green-900">
                  <span>TOTAL:</span>
                  <span>€{formData.calculatedPremium.finalPremium.toFixed(2)}</span>
                </div>
              </div>
            </div>
          )}

          <div className="flex justify-between">
            <button onClick={() => setStep(1)} className="btn-secondary">
              ← Retour
            </button>
            <button onClick={handleNext} className="btn-primary">
              Suivant →
            </button>
          </div>
        </div>
      )}

      {/* Step 3: Summary */}
      {step === 3 && (
        <div className="card space-y-6">
          <h2 className="text-xl font-semibold text-gray-900">Étape 3: Récapitulatif</h2>

          <div className="space-y-4">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Courtier</h3>
              <p className="text-sm text-gray-700">{broker.COMPANY_NAME} ({broker.BROKER_CODE})</p>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Client</h3>
              {formData.customerId ? (
                <p className="text-sm text-gray-700">Client existant (ID: {formData.customerId})</p>
              ) : (
                <p className="text-sm text-gray-700">
                  {formData.customerType === 'IND'
                    ? `${formData.firstName} ${formData.lastName}`
                    : formData.companyName
                  } - {formData.email}
                </p>
              )}
            </div>

            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Produit</h3>
              <p className="text-sm text-gray-700">
                {formData.calculatedPremium?.productName} ({formData.productCode})
              </p>
              {formData.vehiclesCount > 0 && (
                <p className="text-sm text-gray-700">🚗 {formData.vehiclesCount} véhicule(s)</p>
              )}
            </div>

            <div className="bg-das-blue text-white p-4 rounded-lg">
              <h3 className="font-semibold mb-2">Prime Totale</h3>
              <p className="text-3xl font-bold">
                €{formData.calculatedPremium?.finalPremium.toFixed(2)}
              </p>
              <p className="text-sm mt-1">
                Paiement {formData.calculatedPremium?.frequencyLabel.toLowerCase()}
              </p>
            </div>
          </div>

          <div className="flex justify-between">
            <button onClick={() => setStep(2)} className="btn-secondary">
              ← Retour
            </button>
            <button
              onClick={handleSubmit}
              disabled={createMutation.isLoading}
              className="btn-success"
            >
              {createMutation.isLoading ? 'Création...' : '✓ Créer le Contrat'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default CreateContract
