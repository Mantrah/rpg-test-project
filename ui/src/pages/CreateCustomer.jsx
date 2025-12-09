import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { customerApi, bceApi } from '../services/api'
import ButtonSpinner from '../components/ButtonSpinner'

const CreateCustomer = () => {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [customerType, setCustomerType] = useState('IND')
  const [formData, setFormData] = useState({
    // Individual
    firstName: '',
    lastName: '',
    nationalId: '',
    // Business
    companyName: '',
    vatNumber: '',
    // Common
    email: '',
    phone: '',
    street: '',
    houseNbr: '',
    boxNbr: '',
    postalCode: '',
    city: '',
    countryCode: 'BE',
    language: 'FR',
  })

  const [errors, setErrors] = useState({})
  const [bceSearching, setBceSearching] = useState(false)
  const [bceError, setBceError] = useState(null)

  const createMutation = useMutation({
    mutationFn: customerApi.create,
    onSuccess: (data) => {
      // Invalidate customer list cache so it refreshes when we navigate back
      queryClient.invalidateQueries({ queryKey: ['customers'] })
      alert(`Client créé avec succès!`)
      navigate('/customers')
    },
    onError: (error) => {
      alert(`Erreur: ${error.message}`)
    },
  })

  const validate = () => {
    const newErrors = {}

    if (customerType === 'IND') {
      if (!formData.firstName) newErrors.firstName = 'Prénom requis'
      if (!formData.lastName) newErrors.lastName = 'Nom requis'
      if (!formData.nationalId) newErrors.nationalId = 'Numéro national requis'
    } else {
      if (!formData.companyName) newErrors.companyName = 'Nom société requis'
      if (!formData.vatNumber) newErrors.vatNumber = 'Numéro TVA requis'
    }

    if (!formData.email) newErrors.email = 'Email requis'
    if (!formData.street) newErrors.street = 'Rue requise'
    if (!formData.postalCode) newErrors.postalCode = 'Code postal requis'
    if (!formData.city) newErrors.city = 'Ville requise'

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (validate()) {
      createMutation.mutate({
        custType: customerType,
        ...formData,
      })
    }
  }

  const handleChange = (field) => (e) => {
    setFormData(prev => ({ ...prev, [field]: e.target.value }))
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: null }))
    }
  }

  const formatNationalId = (value) => {
    const digits = value.replace(/[^0-9]/g, '').slice(0, 11)
    if (digits.length <= 2) return digits
    if (digits.length <= 4) return `${digits.slice(0, 2)}.${digits.slice(2)}`
    if (digits.length <= 6) return `${digits.slice(0, 2)}.${digits.slice(2, 4)}.${digits.slice(4)}`
    if (digits.length <= 9) return `${digits.slice(0, 2)}.${digits.slice(2, 4)}.${digits.slice(4, 6)}-${digits.slice(6)}`
    return `${digits.slice(0, 2)}.${digits.slice(2, 4)}.${digits.slice(4, 6)}-${digits.slice(6, 9)}.${digits.slice(9)}`
  }

  const handleBceSearch = async () => {
    if (!formData.vatNumber || formData.vatNumber.length < 10) {
      setBceError('Entrez un numéro de TVA valide (ex: BE0403170701)')
      return
    }

    setBceSearching(true)
    setBceError(null)

    try {
      const result = await bceApi.searchByVat(formData.vatNumber)
      const company = result.data

      setFormData(prev => ({
        ...prev,
        companyName: company.companyName || prev.companyName,
        vatNumber: company.vatNumber || prev.vatNumber,
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

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Nouveau Client</h1>
          <p className="mt-2 text-gray-600">
            Enregistrer un nouveau client
          </p>
        </div>
        <button onClick={() => navigate('/customers')} className="btn-secondary">
          Retour
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Customer Type */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Type de Client
          </h2>
          <div className="flex gap-4">
            <label className={`flex-1 p-4 border-2 rounded-lg cursor-pointer transition ${
              customerType === 'IND' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
            }`}>
              <input
                type="radio"
                name="customerType"
                value="IND"
                checked={customerType === 'IND'}
                onChange={() => setCustomerType('IND')}
                className="sr-only"
              />
              <div className="font-medium text-gray-900">Particulier</div>
              <div className="text-sm text-gray-500">Personne physique</div>
            </label>
            <label className={`flex-1 p-4 border-2 rounded-lg cursor-pointer transition ${
              customerType === 'BUS' ? 'border-purple-500 bg-purple-50' : 'border-gray-200 hover:border-gray-300'
            }`}>
              <input
                type="radio"
                name="customerType"
                value="BUS"
                checked={customerType === 'BUS'}
                onChange={() => setCustomerType('BUS')}
                className="sr-only"
              />
              <div className="font-medium text-gray-900">Entreprise</div>
              <div className="text-sm text-gray-500">Personne morale</div>
            </label>
          </div>
        </div>

        {/* Individual Info */}
        {customerType === 'IND' && (
          <div className="card">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Informations Personnelles
            </h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Prénom *</label>
                <input
                  type="text"
                  value={formData.firstName}
                  onChange={handleChange('firstName')}
                  className="input-field"
                />
                {errors.firstName && <p className="text-red-600 text-sm mt-1">{errors.firstName}</p>}
              </div>
              <div>
                <label className="label">Nom *</label>
                <input
                  type="text"
                  value={formData.lastName}
                  onChange={handleChange('lastName')}
                  className="input-field"
                />
                {errors.lastName && <p className="text-red-600 text-sm mt-1">{errors.lastName}</p>}
              </div>
            </div>
            <div className="mt-4">
              <label className="label">Numéro National *</label>
              <input
                type="text"
                value={formData.nationalId}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  nationalId: formatNationalId(e.target.value)
                }))}
                placeholder="00.00.00-000.00"
                className="input-field"
                maxLength={15}
              />
              {errors.nationalId && <p className="text-red-600 text-sm mt-1">{errors.nationalId}</p>}
              <p className="text-xs text-gray-500 mt-1">Format: AA.MM.JJ-XXX.CC</p>
            </div>
          </div>
        )}

        {/* Business Info */}
        {customerType === 'BUS' && (
          <div className="card">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Informations Entreprise
            </h2>

            {/* BCE Search */}
            <div className="bg-purple-50 border border-purple-200 rounded-lg p-4 mb-4">
              <label className="label text-purple-900">Recherche BCE (Banque-Carrefour des Entreprises)</label>
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="N° TVA (ex: BE0403170701)"
                  value={formData.vatNumber}
                  onChange={(e) => setFormData(prev => ({
                    ...prev,
                    vatNumber: e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '')
                  }))}
                  className="input-field flex-1"
                  maxLength={12}
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
              <p className="text-xs text-purple-700 mt-2">
                Entrez le numéro de TVA pour auto-remplir les données de l'entreprise
              </p>
            </div>

            <div>
              <label className="label">Nom Société *</label>
              <input
                type="text"
                value={formData.companyName}
                onChange={handleChange('companyName')}
                className="input-field"
              />
              {errors.companyName && <p className="text-red-600 text-sm mt-1">{errors.companyName}</p>}
            </div>
            <div className="mt-4">
              <label className="label">N° TVA *</label>
              <input
                type="text"
                value={formData.vatNumber}
                className="input-field bg-gray-50"
                readOnly
              />
              {errors.vatNumber && <p className="text-red-600 text-sm mt-1">{errors.vatNumber}</p>}
            </div>
          </div>
        )}

        {/* Contact */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Contact
          </h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Email *</label>
              <input
                type="email"
                value={formData.email}
                onChange={handleChange('email')}
                className="input-field"
              />
              {errors.email && <p className="text-red-600 text-sm mt-1">{errors.email}</p>}
            </div>
            <div>
              <label className="label">Téléphone</label>
              <input
                type="text"
                value={formData.phone}
                onChange={handleChange('phone')}
                placeholder="+32 475 12 34 56"
                className="input-field"
              />
            </div>
          </div>
          <div className="mt-4">
            <label className="label">Langue</label>
            <select
              value={formData.language}
              onChange={handleChange('language')}
              className="input-field w-48"
            >
              <option value="FR">Français</option>
              <option value="NL">Nederlands</option>
              <option value="DE">Deutsch</option>
            </select>
          </div>
        </div>

        {/* Address */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Adresse
          </h2>
          <div className="grid grid-cols-4 gap-4">
            <div className="col-span-2">
              <label className="label">Rue *</label>
              <input
                type="text"
                value={formData.street}
                onChange={handleChange('street')}
                className="input-field"
              />
              {errors.street && <p className="text-red-600 text-sm mt-1">{errors.street}</p>}
            </div>
            <div>
              <label className="label">Numéro</label>
              <input
                type="text"
                value={formData.houseNbr}
                onChange={handleChange('houseNbr')}
                className="input-field"
              />
            </div>
            <div>
              <label className="label">Boîte</label>
              <input
                type="text"
                value={formData.boxNbr}
                onChange={handleChange('boxNbr')}
                className="input-field"
              />
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4 mt-4">
            <div>
              <label className="label">Code Postal *</label>
              <input
                type="text"
                value={formData.postalCode}
                onChange={handleChange('postalCode')}
                className="input-field"
              />
              {errors.postalCode && <p className="text-red-600 text-sm mt-1">{errors.postalCode}</p>}
            </div>
            <div>
              <label className="label">Ville *</label>
              <input
                type="text"
                value={formData.city}
                onChange={handleChange('city')}
                className="input-field"
              />
              {errors.city && <p className="text-red-600 text-sm mt-1">{errors.city}</p>}
            </div>
            <div>
              <label className="label">Pays</label>
              <select
                value={formData.countryCode}
                onChange={handleChange('countryCode')}
                className="input-field"
              >
                <option value="BE">Belgique</option>
                <option value="FR">France</option>
                <option value="NL">Pays-Bas</option>
                <option value="LU">Luxembourg</option>
                <option value="DE">Allemagne</option>
              </select>
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="flex justify-end space-x-4">
          <button
            type="button"
            onClick={() => navigate('/customers')}
            className="btn-secondary"
          >
            Annuler
          </button>
          <button
            type="submit"
            disabled={createMutation.isPending}
            className="btn-success flex items-center gap-2"
          >
            {createMutation.isPending && <ButtonSpinner />}
            {createMutation.isPending ? 'Création...' : 'Créer le Client'}
          </button>
        </div>
      </form>
    </div>
  )
}

export default CreateCustomer
