import React, { useState, useCallback, useEffect } from 'react';
import { Vote, FileText, ScrollText, Menu, X, Wallet, ExternalLink, Shield, Mail, Check } from 'lucide-react';
import { BrowserProvider } from 'ethers';

type Tab = 'voting' | 'proposals' | 'docs';

function App() {
  const [activeTab, setActiveTab] = useState<Tab>('voting');
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [address, setAddress] = useState<string>('');
  const [provider, setProvider] = useState<BrowserProvider | null>(null);
  const [showVerification, setShowVerification] = useState(false);
  const [verificationStep, setVerificationStep] = useState(0);

  const tabs = [
    { id: 'voting', label: 'Voting', icon: Vote },
    { id: 'proposals', label: 'Proposals', icon: ScrollText },
    { id: 'docs', label: 'Documentation', icon: FileText },
  ];

  useEffect(() => {
    const checkConnection = async () => {
      if (window.ethereum) {
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
          setIsConnected(true);
          setAddress(accounts[0]);
          setProvider(new BrowserProvider(window.ethereum));
        }
      }
    };
    
    checkConnection();
  }, []);

  const connectWallet = useCallback(async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        setIsConnected(true);
        setAddress(accounts[0]);
        setProvider(new BrowserProvider(window.ethereum));
      } catch (error) {
        console.error('Error connecting wallet:', error);
      }
    } else {
      alert('Please install MetaMask to use this feature!');
    }
  }, []);

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  const VerificationModal = () => {
    if (!showVerification) return null;

    const handleDavidsonSignIn = () => {
      setVerificationStep(1);
    };

    const handleNFTVerification = () => {
      setVerificationStep(2);
      setTimeout(() => {
        setShowVerification(false);
        setVerificationStep(0);
      }, 2000);
    };

    return (
      <div className="fixed inset-0 bg-black/20 backdrop-blur-sm flex items-center justify-center z-50">
        <div className="soft-card w-full max-w-md p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-xl font-bold gradient-text">Membership Verification</h3>
            <button 
              onClick={() => setShowVerification(false)}
              className="text-gray-500 hover:text-gray-700"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {verificationStep === 0 && (
            <div className="space-y-4">
              <p className="text-gray-600 mb-4">Please sign in with your Davidson account to verify your membership.</p>
              <button
                onClick={handleDavidsonSignIn}
                className="soft-button w-full flex items-center justify-center space-x-2 py-3"
              >
                <Mail className="w-5 h-5" />
                <span>Sign in with Davidson</span>
              </button>
            </div>
          )}

          {verificationStep === 1 && (
            <div className="space-y-4">
              <div className="flex items-center space-x-2 text-green-600 mb-4">
                <Check className="w-5 h-5" />
                <span>Davidson account verified</span>
              </div>
              <p className="text-gray-600 mb-4">Now, let's verify your Club NFT ownership.</p>
              <button
                onClick={handleNFTVerification}
                className="soft-button w-full flex items-center justify-center space-x-2 py-3"
              >
                <Shield className="w-5 h-5" />
                <span>Verify NFT Ownership</span>
              </button>
            </div>
          )}

          {verificationStep === 2 && (
            <div className="text-center space-y-4">
              <div className="flex items-center justify-center space-x-2 text-green-600">
                <Check className="w-8 h-8" />
                <span className="text-lg font-semibold">Verification Complete!</span>
              </div>
              <p className="text-gray-600">Redirecting to dashboard...</p>
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-white via-red-50 to-red-100">
      <VerificationModal />
      <header className="banner-gradient sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="logo-container">
              <Vote className="logo-icon w-8 h-8" />
              <span className="logo-text">Davidson DAO</span>
            </div>

            <div className="hidden md:flex items-center space-x-6">
              <nav className="flex space-x-4">
                {tabs.map(({ id, label, icon: Icon }) => (
                  <button
                    key={id}
                    onClick={() => setActiveTab(id as Tab)}
                    className={`nav-item flex items-center px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200
                      ${activeTab === id ? 'active' : ''}`}
                  >
                    <Icon className="w-4 h-4 mr-2" />
                    {label}
                  </button>
                ))}
              </nav>

              <button
                onClick={() => setShowVerification(true)}
                className="soft-button flex items-center px-4 py-2 text-sm font-medium"
              >
                <Shield className="w-4 h-4 mr-2" />
                Verify Membership
              </button>

              <button
                onClick={connectWallet}
                className="soft-button flex items-center px-4 py-2 text-sm font-medium"
              >
                <Wallet className="w-4 h-4 mr-2" />
                {isConnected ? formatAddress(address) : 'Connect Wallet'}
              </button>
            </div>

            <div className="md:hidden">
              <button
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                className="text-gray-600 hover:text-gray-900"
              >
                {isMobileMenuOpen ? (
                  <X className="h-6 w-6" />
                ) : (
                  <Menu className="h-6 w-6" />
                )}
              </button>
            </div>
          </div>
        </div>

        {isMobileMenuOpen && (
          <div className="md:hidden soft-card mx-4 mt-2">
            <div className="px-2 pt-2 pb-3 space-y-1">
              {tabs.map(({ id, label, icon: Icon }) => (
                <button
                  key={id}
                  onClick={() => {
                    setActiveTab(id as Tab);
                    setIsMobileMenuOpen(false);
                  }}
                  className={`nav-item flex items-center w-full px-3 py-2 rounded-xl text-sm font-medium
                    ${activeTab === id ? 'active' : ''}`}
                >
                  <Icon className="w-4 h-4 mr-2" />
                  {label}
                </button>
              ))}
              <button
                onClick={() => {
                  setShowVerification(true);
                  setIsMobileMenuOpen(false);
                }}
                className="soft-button w-full flex items-center px-3 py-2 text-sm font-medium"
              >
                <Shield className="w-4 h-4 mr-2" />
                Verify Membership
              </button>
              <button
                onClick={connectWallet}
                className="soft-button w-full flex items-center px-3 py-2 text-sm font-medium"
              >
                <Wallet className="w-4 h-4 mr-2" />
                {isConnected ? formatAddress(address) : 'Connect Wallet'}
              </button>
            </div>
          </div>
        )}
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {!isConnected && (
          <div className="soft-card p-8 text-center">
            <Wallet className="w-12 h-12 text-red-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold gradient-text mb-2">Connect Your Wallet</h2>
            <p className="text-gray-600 mb-4">Please connect your wallet to access DAO features</p>
            <button
              onClick={connectWallet}
              className="soft-button px-6 py-3"
            >
              Connect Wallet
            </button>
          </div>
        )}

        {activeTab === 'voting' && (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold gradient-text mb-6">Active Votes</h2>
            <div className="grid gap-6 md:grid-cols-2">
              {[1, 2, 3].map((i) => (
                <div key={i} className="soft-card p-6">
                  <h3 className="text-lg font-semibold mb-2 text-red-500">Governance Proposal #{i}</h3>
                  <p className="text-gray-600 mb-4">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
                  <div className="flex space-x-4">
                    <button 
                      className={`soft-button flex-1 ${!isConnected && 'opacity-50 cursor-not-allowed'}`}
                      disabled={!isConnected}
                    >
                      Vote For
                    </button>
                    <button 
                      className={`border border-red-300 hover:bg-red-50 px-4 py-2 rounded-xl transition-all duration-200 flex-1 ${!isConnected && 'opacity-50 cursor-not-allowed'}`}
                      disabled={!isConnected}
                    >
                      Vote Against
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'proposals' && (
          <div className="space-y-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold gradient-text">Proposals</h2>
              <button 
                className={`soft-button ${!isConnected && 'opacity-50 cursor-not-allowed'}`}
                disabled={!isConnected}
              >
                Create New Proposal
              </button>
            </div>
            <div className="grid gap-6">
              {[1, 2, 3].map((i) => (
                <div key={i} className="soft-card p-6">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="text-lg font-semibold text-red-500">Community Proposal #{i}</h3>
                    <span className={`status-badge ${
                      i === 1 ? 'status-active' : 
                      i === 2 ? 'status-pending' : 
                      'status-failed'
                    }`}>
                      {i === 1 ? 'Passed' : i === 2 ? 'Active' : 'Failed'}
                    </span>
                  </div>
                  <p className="text-gray-600 mb-4">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
                  <div className="flex justify-between items-center text-sm text-gray-500">
                    <span>Proposed by: {formatAddress('0x1234567890abcdef')}</span>
                    <span>Ends in: 3 days</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'docs' && (
          <div className="content-section">
            <h2 className="text-2xl font-bold gradient-text mb-6">Documentation</h2>
            <div className="space-y-6">
              <div className="doc-card">
                <h3 className="text-xl font-semibold text-red-500 mb-4">About Davidson DAO</h3>
                <p className="text-gray-600">
                  Davidson DAO is a decentralized autonomous organization focused on community-driven governance
                  and decision-making. Our mission is to create a transparent and efficient system for proposal
                  creation, voting, and implementation.
                </p>
              </div>
              
              <div className="doc-card">
                <h3 className="text-xl font-semibold text-red-500 mb-4">Getting Started</h3>
                <div className="space-y-4">
                  <div className="bg-red-50/50 p-6 rounded-xl">
                    <h4 className="text-lg font-semibold text-red-500 mb-3">1. Set Up Your Wallet</h4>
                    <p className="text-gray-600 mb-4">To participate in the DAO, you'll need a Web3 wallet:</p>
                    <ul className="space-y-2 text-gray-600">
                      <li>
                        <a 
                          href="https://metamask.io/download/" 
                          target="_blank" 
                          rel="noopener noreferrer"
                          className="soft-link inline-flex items-center"
                        >
                          MetaMask <ExternalLink className="w-4 h-4 ml-1" />
                        </a>
                        {" "}- Most popular desktop wallet
                      </li>
                      <li>
                        <a 
                          href="https://trustwallet.com/download" 
                          target="_blank" 
                          rel="noopener noreferrer"
                          className="soft-link inline-flex items-center"
                        >
                          Trust Wallet <ExternalLink className="w-4 h-4 ml-1" />
                        </a>
                        {" "}- Great for mobile users
                      </li>
                    </ul>
                  </div>

                  <div className="bg-red-50/50 p-6 rounded-xl">
                    <h4 className="text-lg font-semibold text-red-500 mb-3">2. Understanding Gas Fees</h4>
                    <p className="text-gray-600 mb-4">Our DAO operates on two layers:</p>
                    <ul className="list-disc pl-6 space-y-2 text-gray-600">
                      <li>
                        <span className="font-semibold text-red-500">Off-chain Voting:</span> Initial voting and proposal creation is free
                      </li>
                      <li>
                        <span className="font-semibold text-red-500">On-chain Execution:</span> Only approved proposals require gas fees
                      </li>
                    </ul>
                  </div>

                  <div className="bg-red-50/50 p-6 rounded-xl">
                    <h4 className="text-lg font-semibold text-red-500 mb-3">3. Best Practices</h4>
                    <ul className="list-disc pl-6 space-y-2 text-gray-600">
                      <li>Always verify transaction details before signing</li>
                      <li>Keep your wallet's private keys secure</li>
                      <li>Read proposal details thoroughly before voting</li>
                      <li>Participate in discussions to make informed decisions</li>
                    </ul>
                  </div>
                </div>
              </div>

              <div className="doc-card">
                <h3 className="text-xl font-semibold text-red-500 mb-4">Need Help?</h3>
                <p className="text-gray-600">
                  Join our{' '}
                  <a 
                    href="https://discord.gg/davidsondao" 
                    target="_blank" 
                    rel="noopener noreferrer"
                    className="soft-link inline-flex items-center"
                  >
                    Discord community <ExternalLink className="w-4 h-4 ml-1" />
                  </a>
                  {' '}for support and discussions.
                </p>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;