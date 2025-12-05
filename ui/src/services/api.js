import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Response interceptor
api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    const message = error.response?.data?.error?.message || error.message || 'An error occurred';
    const code = error.response?.data?.error?.code || 'UNKNOWN';
    return Promise.reject({ message, code, status: error.response?.status });
  }
);

// Dashboard
export const dashboardApi = {
  getStats: () => api.get('/dashboard/stats'),
  getClaimsByStatus: () => api.get('/dashboard/claims-by-status'),
  getRecentClaims: (limit = 5) => api.get(`/dashboard/recent-claims?limit=${limit}`),
};

// Brokers
export const brokerApi = {
  getAll: (status = null) => api.get('/brokers', { params: { status } }),
  getById: (id) => api.get(`/brokers/${id}`),
  getByCode: (code) => api.get(`/brokers/code/${code}`),
  create: (data) => api.post('/brokers', data),
};

// Customers
export const customerApi = {
  getAll: (status = null) => api.get('/customers', { params: { status } }),
  getById: (id) => api.get(`/customers/${id}`),
  getByEmail: (email) => api.get(`/customers/email/${email}`),
  getContracts: (id) => api.get(`/customers/${id}/contracts`),
  create: (data) => api.post('/customers', data),
};

// Products
export const productApi = {
  getAll: () => api.get('/products'),
  getById: (id) => api.get(`/products/${id}`),
  getByCode: (code) => api.get(`/products/code/${code}`),
  getGuarantees: (id) => api.get(`/products/${id}/guarantees`),
  calculatePremium: (data) => api.post('/products/calculate', data),
};

// Contracts
export const contractApi = {
  getAll: (status = null) => api.get('/contracts', { params: { status } }),
  getById: (id) => api.get(`/contracts/${id}`),
  getByReference: (reference) => api.get(`/contracts/reference/${reference}`),
  getBrokerContracts: (brokerId) => api.get(`/contracts/broker/${brokerId}`),
  getClaims: (id) => api.get(`/contracts/${id}/claims`),
  create: (data) => api.post('/contracts', data),
  calculatePremium: (data) => api.post('/contracts/calculate', data),
};

// Claims
export const claimApi = {
  getAll: (status = null) => api.get('/claims', { params: { status } }),
  getById: (id) => api.get(`/claims/${id}`),
  getByReference: (reference) => api.get(`/claims/reference/${reference}`),
  getStats: () => api.get('/claims/stats'),
  checkCoverage: (data) => api.post('/claims/check-coverage', data),
  validate: (data) => api.post('/claims/validate', data),
  create: (data) => api.post('/claims', data),
};

export default api;
