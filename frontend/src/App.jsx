import { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import './App.css';

const TOKEN_ADDRESS = "0xf85579BD4Dc4c29D42C47bb5432A3BDb3f89147b";
const GOVERNOR_ADDRESS = "0x77786a1decD3a17374f2d2b8212be4e1Ce81204C";

const TOKEN_ABI = ["function balanceOf(address owner) view returns (uint256)","function deposit(uint256 amount) external","function getVotingPower(address account) public view returns (uint256)","function approve(address spender, uint256 amount) public returns (bool)"];
const GOVERNOR_ABI = ["function createProposal(string description, uint256 duration) external","function vote(uint256 proposalId, bool support) external","function proposals(uint256) public view returns (string description, uint256 votesFor, uint256 votesAgainst, uint256 endTime, bool executed)"];

function App() {
  const [account, setAccount] = useState("");
  const [balance, setBalance] = useState("0");
  const [power, setPower] = useState("0");
  const [proposals, setProposals] = useState([]);
  const [status, setStatus] = useState("Ready");

  const fetchData = useCallback(async () => {
    if (!account || !window.ethereum) return;
    try {
      const provider = new ethers.BrowserProvider(window.ethereum, "any");
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TOKEN_ABI, provider);
      const govContract = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, provider);
      
      const [bal, p] = await Promise.all([
        tokenContract.balanceOf(account),
        tokenContract.getVotingPower(account)
      ]);
      setBalance(ethers.formatUnits(bal, 18));
      setPower(ethers.formatUnits(p, 18));

      let list = [];
      for (let i = 0; i < 10; i++) {
        try {
          const prop = await govContract.proposals(i);
          if (!prop.description) break;
          list.push({ id: i, desc: prop.description, votes: ethers.formatUnits(prop.votesFor, 18) });
        } catch (e) { break; }
      }
      setProposals(list.reverse());
      setStatus("Synced");
    } catch (err) { setStatus("Sync Error"); }
  }, [account]);

  useEffect(() => {
    if (account) { fetchData(); const inv = setInterval(fetchData, 8000); return () => clearInterval(inv); }
  }, [account, fetchData]);

  const connectWallet = async () => {
    try {
        const accs = await window.ethereum.request({ method: 'eth_requestAccounts' });
        setAccount(accs[0]);
    } catch (err) { console.error(err); }
  };

  return (
    <div className="app-container">
      <div className="content-wrapper">
        <header className="header">
          <h2>🏛️ Master's DAO Dashboard</h2>
          <button onClick={fetchData} className="btn-sync">🔄 Sync</button>
        </header>

        {!account ? (
          <div className="connect-container">
            <button onClick={connectWallet} className="btn-main">Connect MetaMask Wallet</button>
          </div>
        ) : (
          <main className="dashboard-content">
            <div className="stats-grid">
              <div className="stat-card">
                <small className="label">TOTAL BALANCE</small>
                <h2 className="text-blue">{parseFloat(balance).toLocaleString()} GTK</h2>
              </div>
              <div className="stat-card">
                <small className="label">⚡ VOTING POWER</small>
                <h2 className="text-green">{parseFloat(power).toLocaleString()}</h2>
              </div>
            </div>

            <div className="action-buttons">
              <button className="btn-stake">Stake 10 Tokens</button>
              <button className="btn-prop">+ Create Proposal</button>
            </div>

            <section className="proposals-section">
              <h3 className="section-title">Active Governance Proposals</h3>
              {proposals.length === 0 ? <p className="empty-msg">No proposals found.</p> : 
                proposals.map(p => (
                  <div key={p.id} className="proposal-card">
                    <div className="proposal-info">
                      <strong>{p.desc} (ID: {p.id})</strong>
                      <small className="label">Current Votes: {p.votes}</small>
                    </div>
                    <button className="btn-vote">Vote YES</button>
                  </div>
                ))
              }
            </section>
          </main>
        )}
      </div>
      <div className="status-bar">System Status: {status}</div>
    </div>
  );
}

export default App;