const ErrorMessage = ({ message, code }) => {
  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-4">
      <div className="flex items-start">
        <div className="text-red-500 text-2xl mr-3">⚠️</div>
        <div className="flex-1">
          <h3 className="text-red-800 font-medium">Erreur</h3>
          <p className="text-red-700 mt-1">{message}</p>
          {code && (
            <p className="text-red-600 text-sm mt-1">Code: {code}</p>
          )}
        </div>
      </div>
    </div>
  )
}

export default ErrorMessage
