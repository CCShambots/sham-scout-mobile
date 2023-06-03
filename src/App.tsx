import React from 'react';
import './App.css';
import {HashRouter, NavLink, Route, Routes} from "react-router-dom";
import HomePage from "./pages/HomePage";
import MatchPage from "./pages/MatchPage";
import ScanPage from "./pages/ScanPage";
import SchedulePage from "./pages/SchedulePage";
import SettingsPage from "./pages/SettingsPage";

function App() {
  return (
      <HashRouter basename={`/`}>
        <Routes>
          <Route path='' element={ <HomePage /> } />
          <Route path='/scan' element={ <ScanPage /> } />
          <Route path='/matches' element={ <MatchPage /> } />
          <Route path='/schedule' element={ <SchedulePage /> } />
          <Route path='/settings' element={ <SettingsPage /> } />

          <Route path="/*" element={<NavLink to="/" />}  /> {/* navigate to default route if no url matched */}
        </Routes>

      </HashRouter>
  );
}

export default App;
