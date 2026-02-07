import { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import './App.css';

const TOKEN_ADDRESS = "0xF6F037333eD518A666C2A688CbdFD81763149D8B";
const GOVERNOR_ADDRESS = "0x96F35640F082E5D4cc1439DA0397C976bAC71188";

const TOKEN_ABI = [
  "function balanceOf(address owner) view returns (uint256)",
  "function deposit(uint256 amount) external",
  "function withdraw(uint256 amount) external",
  "function getVotingPower(address account) public view returns (uint256)",
  "function approve(address spender, uint256 amount) public returns (bool)"
];

const GOVERNOR_ABI = [
  "function createProposal(string description, uint256 duration) external",
  "function vote(uint256 proposalId, bool support) external",
  "function proposals(uint256) public view returns (string description, uint256 votesFor, uint256 votesAgainst, uint256 endTime, bool executed)"
];

function App() {
  const [account, setAccount] = useState("");
  const [balance, setBalance] = useState("0");
  const [power, setPower] = useState("0");
  const [proposals, setProposals] = useState([]);
  const [status, setStatus] = useState("Ready");

  const fetchData = useCallback(async () => {
    if (!account || !window.ethereum) return;
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TOKEN_ABI, provider);
      const govContract = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, provider);

      const bal = await tokenContract.balanceOf(account).catch(() => 0n);
      setBalance(ethers.formatUnits(bal, 18));

      try {
        const p = await tokenContract.getVotingPower(account);
        setPower(ethers.formatUnits(p, 18));
      } catch (e) { setPower("0"); }

      let list = [];
      for (let i = 0; i < 10; i++) {
        try {
          const prop = await govContract.proposals(i);
          if (!prop.description || prop.description.trim() === "") break;
          list.push({ 
            id: i, 
            desc: prop.description, 
            votes: ethers.formatUnits(prop.votesFor, 18) 
          });
        } catch (e) { break; }
      }
      setProposals(list.reverse());
      setStatus("Synced");
    } catch (err) { console.error(err); }
  }, [account]);

  useEffect(() => {
    if (account) {
      fetchData();
      const interval = setInterval(fetchData, 15000);
      return () => clearInterval(interval);
    }
  }, [account, fetchData]);

  const connectWallet = async () => {
    if (!window.ethereum) return alert("Install MetaMask");
    const accs = await window.ethereum.request({ method: 'eth_requestAccounts' });
    setAccount(accs[0]);
  };

  // --- ACTIONS ---

  const stakeTokens = async () => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TOKEN_ABI, signer);
      const amount = ethers.parseUnits("10", 18);

      setStatus("Approving...");
      await (await tokenContract.approve(TOKEN_ADDRESS, amount)).wait();
      
      setStatus("Staking...");
      await (await tokenContract.deposit(amount)).wait();
      
      setStatus("Stake Success!");
      fetchData();
    } catch (e) { setStatus("Error Staking"); }
  };

  const withdrawTokens = async () => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TOKEN_ABI, signer);

      setStatus("Unstaking...");
      await (await tokenContract.withdraw(ethers.parseUnits("10", 18))).wait();
      
      setStatus("Unstaked!");
      fetchData();
    } catch (e) { setStatus("Error Unstaking"); }
  };

  const createProposal = async () => {
    const desc = prompt("Enter Proposal Description:");
    if (!desc) return;
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const govContract = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, signer);

      setStatus("Creating...");
      await (await govContract.createProposal(desc, 86400)).wait(); // 24hr duration
      
      setStatus("Proposal Created!");
      fetchData();
    } catch (e) { 
      alert("Failed. Ensure you have 50 GTK staked.");
      setStatus("Creation Failed"); 
    }
  };

  const vote = async (id) => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const govContract = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, signer);

      setStatus("Voting...");
      await (await govContract.vote(id, true)).wait();
      
      setStatus("Voted!");
      fetchData();
    } catch (e) { setStatus("Vote Failed"); }
  };

  return (
    <div className="app-container">
      <div className="content-wrapper">
        <header className="header">
          <h2>🏛️ Master's DAO</h2>
          <button onClick={fetchData} className="btn-sync">🔄 Refresh</button>
        </header>

        {!account ? (
          <div className="connect-container">
            <button onClick={connectWallet} className="btn-main">Connect Wallet</button>
          </div>
        ) : (
          <main className="dashboard-content">
            <div className="stats-grid">
              <div className="stat-card">
                <small className="label">Balance</small>
                <h2 className="text-blue">{parseFloat(balance).toFixed(2)} GTK</h2>
              </div>
              <div className="stat-card">
                <small className="label">⚡ Power</small>
                <h2 className="text-green">{parseFloat(power).toFixed(2)}</h2>
              </div>
            </div>

            <div className="action-buttons">
              <button onClick={stakeTokens} className="btn-stake">Stake 10</button>
              <button onClick={withdrawTokens} className="btn-withdraw">Unstake 10</button>
              <button onClick={createProposal} className="btn-prop">+ Proposal</button>
            </div>

            <section className="proposals-section">
              <h3 className="section-title">Active Proposals</h3>
              {proposals.length === 0 ? <p>No data found.</p> : 
                proposals.map(p => (
                  <div key={p.id} className="proposal-card">
                    <div className="proposal-info">
                      <strong>{p.desc}</strong>
                      <div className="prop-meta">ID: #{p.id} | Votes: {p.votes}</div>
                    </div>
                    <button onClick={() => vote(p.id)} className="btn-vote">Vote YES</button>
                  </div>
                ))
              }
            </section>
          </main>
        )}
      </div>
      <div className="status-bar">Status: {status}</div>
    </div>
  );
}

export default App;