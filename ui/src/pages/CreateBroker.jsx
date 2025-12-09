import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { brokerApi, bceApi } from '../services/api'
import ButtonSpinner from '../components/ButtonSpinner'

const CreateBroker = () => {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [formData, setFormData] = useState({
    brokerCode: '',
    companyName: '',
    vatNumber: '',
    fsmaNumber: '',
    contactName: '',
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
  const [bceSuccess, setBceSuccess] = useState(false)

  // Create mutation
  const createMutation = useMutation({
    mutationFn: brokerApi.create,
    onSuccess: (data) => {
      // Invalidate broker list cache so it refreshes when we navigate back
      queryClient.invalidateQueries({ queryKey: ['brokers'] })
      alert(`Courtier créé avec succès!\n\nCode: ${data.data.brokerCode}`)
      navigate('/brokers')
    },
    onError: (error) => {
      alert(`Erreur: ${error.message}`)
    },
  })

  // BCE search
  const handleBceSearch = async () => {
    if (!formData.vatNumber || formData.vatNumber.length < 10) {
      setBceError('Entrez un numéro de TVA valide (ex: BE0123456789)')
      return
    }

    setBceSearching(true)
    setBceError(null)
    setBceSuccess(false)

    try {
      const result = await bceApi.searchByVat(formData.vatNumber)
      const company = result.data

      // Auto-fill form
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
      setBceSuccess(true)
    } catch (error) {
      setBceError(error.message || 'Entreprise non trouvée dans la BCE')
    } finally {
      setBceSearching(false)
    }
  }

  const validate = () => {
    const newErrors = {}

    if (!formData.brokerCode) newErrors.brokerCode = 'Code courtier requis'
    if (!formData.companyName) newErrors.companyName = 'Nom société requis'
    if (!formData.fsmaNumber) newErrors.fsmaNumber = 'Numéro FSMA requis'
    if (!formData.email) newErrors.email = 'Email requis'
    if (!formData.contactName) newErrors.contactName = 'Nom contact requis'
    if (!formData.street) newErrors.street = 'Rue requise'
    if (!formData.postalCode) newErrors.postalCode = 'Code postal requis'
    if (!formData.city) newErrors.city = 'Ville requise'

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (validate()) {
      createMutation.mutate(formData)
    }
  }

  const handleChange = (field) => (e) => {
    setFormData(prev => ({ ...prev, [field]: e.target.value }))
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: null }))
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Nouveau Courtier</h1>
          <p className="mt-2 text-gray-600">
            Enregistrer un nouveau courtier partenaire DAS Belgium
          </p>
        </div>
        <button onClick={() => navigate('/brokers')} className="btn-secondary">
          Retour
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* BCE Search */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Recherche BCE (Banque-Carrefour des Entreprises)
          </h2>
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="N° TVA (ex: BE0123456789)"
                value={formData.vatNumber}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  vatNumber: e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '')
                }))}
                className="input-field flex-1"
              />
              <button
                type="button"
                onClick={handleBceSearch}
                disabled={bceSearching}
                className="btn-primary whitespace-nowrap"
              >
                {bceSearching ? 'Recherche...' : 'Rechercher BCE'}
              </button>
            </div>
            {bceError && <p className="text-red-600 text-sm mt-2">{bceError}</p>}
            {bceSuccess && (
              <p className="text-green-600 text-sm mt-2">
                Données BCE récupérées avec succès
              </p>
            )}
            <p className="text-xs text-blue-700 mt-2">
              Entrez le numéro de TVA pour auto-remplir les données de l'entreprise
            </p>
          </div>
        </div>

        {/* Company Info */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Informations Société
          </h2>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Code Courtier *</label>
              <input
                type="text"
                value={formData.brokerCode}
                onChange={handleChange('brokerCode')}
                placeholder="ex: BRK001"
                className="input-field"
                maxLength={10}
              />
              {errors.brokerCode && <p className="text-red-600 text-sm mt-1">{errors.brokerCode}</p>}
            </div>
            <div>
              <label className="label">N° FSMA *</label>
              <input
                type="text"
                value={formData.fsmaNumber}
                onChange={handleChange('fsmaNumber')}
                placeholder="ex: 123456A"
                className="input-field"
              />
              {errors.fsmaNumber && <p className="text-red-600 text-sm mt-1">{errors.fsmaNumber}</p>}
              <p className="text-xs text-gray-500 mt-1">Numéro d'agrément FSMA</p>
            </div>
          </div>

          <div className="mt-4">
            <label className="label">Nom Société *</label>
            <input
              type="text"
              value={formData.companyName}
              onChange={handleChange('companyName')}
              className="input-field"
            />
            {errors.companyName && <p className="text-red-600 text-sm mt-1">{errors.companyName}</p>}
          </div>

          <div className="grid grid-cols-2 gap-4 mt-4">
            <div>
              <label className="label">N° TVA</label>
              <input
                type="text"
                value={formData.vatNumber}
                onChange={handleChange('vatNumber')}
                className="input-field bg-gray-50"
                readOnly
              />
            </div>
            <div>
              <label className="label">Langue</label>
              <select
                value={formData.language}
                onChange={handleChange('language')}
                className="input-field"
              >
                <option value="FR">Français</option>
                <option value="NL">Nederlands</option>
                <option value="EN">English</option>
              </select>
            </div>
          </div>
        </div>

        {/* Contact */}
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Contact
          </h2>

          <div className="grid grid-cols-1 gap-4">
            <div>
              <label className="label">Nom du Contact *</label>
              <input
                type="text"
                value={formData.contactName}
                onChange={handleChange('contactName')}
                placeholder="ex: Jean Dupont"
                className="input-field"
              />
              {errors.contactName && <p className="text-red-600 text-sm mt-1">{errors.contactName}</p>}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 mt-4">
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
                placeholder="+32 2 123 45 67"
                className="input-field"
              />
            </div>
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
              </select>
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="flex justify-end space-x-4">
          <button
            type="button"
            onClick={() => navigate('/brokers')}
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
            {createMutation.isPending ? 'Création...' : 'Créer le Courtier'}
          </button>
        </div>
      </form>
    </div>
  )
}

export default CreateBroker
