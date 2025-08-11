import { useState } from "react";
import { Navbar, Button, TextInput } from "flowbite-react";
import { Link, useNavigate } from "react-router-dom";

export function NavbarComponent() {
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearching, setIsSearching] = useState(false);
  const navigate = useNavigate();

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault();

    if (!searchQuery.trim() || isSearching) {
      return;
    }

    setIsSearching(true);
    navigate(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
    setSearchQuery("");
    setIsSearching(false);
  }

  return (
    <Navbar fluid className="border-b px-4 bg-white shadow-sm">
      {/* Left - Logo */}
      <Link to="/" className="text-xl font-semibold text-blue-600 whitespace-nowrap">
        MyStackOverflow
      </Link>

      {/* Center - Search */}
      <div className="flex flex-1 justify-center">
        <form onSubmit={handleSearch} className="flex w-full max-w-lg gap-2">
          <TextInput
            type="text"
            placeholder="Search programming questions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="flex-1"
            disabled={isSearching}
          />
          <Button
            type="submit"
            color="blue"
            disabled={!searchQuery.trim() || isSearching}
            className="px-4"
          >
            {isSearching ? (
              <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
            ) : (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            )}
          </Button>
        </form>
      </div>

      {/* Right - optional future buttons */}
      <div className="flex items-center gap-2">
        {/* Add login/signup buttons here later */}
      </div>
    </Navbar>
  );
}
