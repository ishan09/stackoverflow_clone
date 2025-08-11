import { Routes, Route } from "react-router-dom";
import { NavbarComponent } from "./components/NavbarComponent";
import { LandingPage } from "./pages/LandingPage";
import { SearchResultsPage } from "./pages/SearchResultsPage";
import { QuestionPage } from "./pages/QuestionPage";

export default function App() {
  return (
    <div className="min-h-screen flex flex-col">
      <NavbarComponent />
      <div className="flex-1">
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/search" element={<SearchResultsPage />} />
          <Route path="/question/:id" element={<QuestionPage />} />
        </Routes>
      </div>
    </div>
  );
}