import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import BrokerList from './pages/BrokerList'
import CreateBroker from './pages/CreateBroker'
import ContractList from './pages/ContractList'
import CreateContract from './pages/CreateContract'
import DeclareClaim from './pages/DeclareClaim'

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Dashboard />} />
        <Route path="brokers" element={<BrokerList />} />
        <Route path="brokers/create" element={<CreateBroker />} />
        <Route path="contracts" element={<ContractList />} />
        <Route path="contracts/create" element={<CreateContract />} />
        <Route path="contracts/:id/claim" element={<DeclareClaim />} />
      </Route>
    </Routes>
  )
}

export default App
