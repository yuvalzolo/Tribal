# Chess Game Application Requirements

## Introduction

This document outlines the requirements for building a Chess Game application in Salesforce. The application will manage chess players, track games between players, record game outcomes, and maintain a ranking system based on standard ELO ratings with K-factor calculation. Games will be recorded after being played (not played within the application), and the system will automatically update player statistics and rankings after each completed game. The application includes an interactive visual chess board UI for viewing and replaying games.

## Requirements

### 1. Data Model Setup

**User Story:**
As an admin, I want the data model to be set up with the core objects and fields so that the application has a solid data foundation for managing players, games, and rankings.

**Acceptance Criteria:**
- **Player Object** (Player__c) is created with the following fields:
  - Player Name (Text, 80 characters) - Name of the chess player
  - Email (Email) - Player's contact email
  - ELO Rating (Number, 0 decimal places) - Current chess rating (default: 1200)
  - Total Games Played (Number, 0 decimal places) - Count of all games
  - Wins (Number, 0 decimal places) - Count of games won
  - Losses (Number, 0 decimal places) - Count of games lost
  - Draws (Number, 0 decimal places) - Count of drawn games
  - Active Player (Checkbox) - Whether player is currently active (default: true)
  - Registration Date (Date) - When player joined
  - K Factor (Number, 0 decimal places) - ELO calculation factor (default: 32)

- **Chess Game Object** (Chess_Game__c) is created with the following fields:
  - Game Name (Text, 80 characters) - Auto-generated game identifier
  - White Player (Lookup to Player__c) - Player playing white pieces (required)
  - Black Player (Lookup to Player__c) - Player playing black pieces (required)
  - Game Status (Picklist: Scheduled, In Progress, Completed, Abandoned) - Current game state
  - Winner (Lookup to Player__c) - Player who won (if applicable)
  - Game Result (Picklist: White Wins, Black Wins, Draw, Abandoned) - Final outcome
  - Start Date Time (DateTime) - When game started
  - End Date Time (DateTime) - When game ended
  - Game Notation (Long Text Area, 32,768 characters) - PGN notation for the complete game
  - Number of Moves (Number, 0 decimal places) - Total moves in game
  - White Player ELO Before (Number, 0 decimal places) - White player's rating before game
  - Black Player ELO Before (Number, 0 decimal places) - Black player's rating before game
  - White Player ELO After (Number, 0 decimal places) - White player's rating after game
  - Black Player ELO After (Number, 0 decimal places) - Black player's rating after game
  - ELO Change (Number, 0 decimal places) - Rating points gained/lost
  - Current Position FEN (Text, 255 characters) - Current board position in FEN notation

- **Player Rank Object** (Player_Rank__c) is created with the following fields:
  - Rank Name (Text, 80 characters) - Auto-generated rank identifier
  - Player (Lookup to Player__c) - Associated player (required)
  - Rank Position (Number, 0 decimal places) - Current ranking position
  - ELO Rating (Number, 0 decimal places) - Rating at this point in time
  - Rank Date (Date) - Date of this ranking snapshot
  - Games Played (Number, 0 decimal places) - Total games at this point
  - Win Rate (Percent, 2 decimal places) - Percentage of games won

- Relationships are properly configured:
  - Chess_Game__c has two lookup relationships to Player__c (White Player and Black Player)
  - Chess_Game__c has one lookup relationship to Player__c for Winner
  - Player_Rank__c has a lookup relationship to Player__c

### 2. Player Management

**User Story:**
As a chess club administrator, I want to manage player profiles and view their statistics so that I can track player information and performance.

**Acceptance Criteria:**
- A custom tab for the Player object is created and accessible from the main navigation
- A list view "All Players" displays all player records with key fields (Name, ELO Rating, Total Games, Wins, Losses, Draws, Active Player)
- A list view "Active Players" displays only active players sorted by ELO Rating (descending)
- A list view "Top 10 Players" displays the top 10 players by ELO Rating
- Player records display all relevant fields in an organized layout with sections for Contact Info, Statistics, and ELO Rating
- Users can create, edit, and view player records
- Player statistics (Total Games, Wins, Losses, Draws, Win Rate) are visible on the player record page
- A compact layout displays Player Name, ELO Rating, and Total Games in highlights panel
- Related lists show Chess Games (as White Player and Black Player) and Player Rank history

### 3. Game Management

**User Story:**
As a chess club administrator, I want to create and manage chess games between players so that I can record game outcomes and maintain accurate records with proper ELO calculations.

**Acceptance Criteria:**
- A custom tab for the Chess Game object is created and accessible from the main navigation
- A list view "All Games" displays all game records with key fields (Game Name, White Player, Black Player, Status, Result, Start Date Time)
- A list view "In Progress Games" displays only games with status "In Progress"
- A list view "Completed Games" displays only games with status "Completed" sorted by End Date Time (descending)
- A list view "Recent Games" displays games from the last 30 days
- Users can create new game records by selecting two different players (validation prevents same player for both sides)
- Users can update game status, record game notation in PGN format, and set the winner
- When a game is marked as "Completed", the Game Result field must be populated
- The End Date Time is automatically set when game status changes to "Completed"
- When a game is completed, the system captures both players' ELO ratings before the game (White Player ELO Before, Black Player ELO Before)
- ELO ratings are calculated using standard ELO formula with K-factor after game completion
- The ELO Change field shows the rating points gained by the winner (or 0 for draws)
- Both players' new ELO ratings are stored (White Player ELO After, Black Player ELO After)
- A compact layout displays Game Name, White Player, Black Player, Result, and Game Status

### 4. Automated ELO Calculation and Ranking System

**User Story:**
As a chess club administrator, I want an automated ranking system that calculates ELO ratings using the standard formula and tracks player rankings over time so that I can see accurate player progression and compare performance.

**Acceptance Criteria:**
- A custom tab for the Player Rank object is created and accessible from the main navigation
- A list view "Current Rankings" displays all player rank records sorted by Rank Position (ascending)
- A list view "Latest Rankings" displays the most recent rank snapshot for each player
- When a game is completed with result "White Wins", "Black Wins", or "Draw":
  - Player statistics (Wins, Losses, Draws, Total Games) are updated automatically for both players
  - Expected scores are calculated using ELO formula: E = 1 / (1 + 10^((opponent_rating - player_rating)/400))
  - Actual scores are assigned: 1 for win, 0.5 for draw, 0 for loss
  - New ELO ratings are calculated using: New Rating = Old Rating + K * (Actual Score - Expected Score)
  - K-factor is retrieved from each player's K Factor field (default: 32)
  - Player ELO Rating fields are updated with the new calculated ratings
  - A new Player Rank record is created for each player with their updated rating
- The Rank Position field is calculated by comparing each player's ELO rating to all other active players
- Win Rate is calculated as (Wins / Total Games) * 100
- Users can view historical ranking data for each player through related lists on the Player record
- A compact layout displays Player Name, Rank Position, ELO Rating, and Rank Date
- Games with result "Abandoned" do not trigger ELO calculations or ranking updates

### 5. Interactive Chess Game Display UI

**User Story:**
As a chess player or administrator, I want to view games on an interactive visual chess board with player information and move history so that I can analyze games, review positions, and replay move sequences.

**Acceptance Criteria:**
- A Lightning Web Component "Chess Game Viewer" is created to display chess games visually
- The component displays a visual chess board (8x8 grid) with proper square colors (light and dark alternating)
- Chess pieces are rendered using standard chess symbols or icons (King, Queen, Rook, Bishop, Knight, Pawn)
- Player information panels are displayed showing:
  - Player names (White and Black)
  - Current ELO ratings in parentheses (e.g., "Black (2300)")
  - Captured pieces for each player
- A move history panel is displayed on the right side showing:
  - Numbered list of all moves in algebraic notation (e.g., "1. E4 D5")
  - Scrollable list for games with many moves
  - Current move highlighted in the list
- The chess board displays the current position based on the game's FEN notation or PGN moves
- Users can navigate through move history to see board positions at different points in the game
- Visual indicators show whose turn it is (White or Black)
- The component integrates with the Chess Game object to load game data (players, moves, positions)
- A Lightning App Page "Chess Game Viewer" is created to host the component
- A custom tab "Game Viewer" is created for easy access to the chess board UI
- The component is responsive and displays properly on desktop and tablet devices
- Board coordinates (A-H, 1-8) are displayed on the edges of the board for reference
- The UI uses a clean, modern design with proper contrast and readability

## Special Requirements

- All custom objects must have appropriate compact layouts for displaying key information in highlights panels
- The application must include a custom application called "Chess Game Manager" that groups all chess-related tabs together (Player, Chess Game, Player Rank, Game Viewer)
- A permission set called "Chess Game Admin" must be created to grant full access to all custom objects, fields, tabs, and Lightning components for chess administrators
- Game notation should support standard PGN (Portable Game Notation) format
- Board positions should support FEN (Forsyth-Edwards Notation) format for accurate position representation
- The system must prevent a player from playing against themselves through validation (White Player ≠ Black Player)
- ELO calculation automation should be implemented using Apex trigger or Flow to ensure accurate and immediate rating updates
- Initial ELO rating for new players defaults to 1200 (standard starting rating)
- K-factor defaults to 32 but can be adjusted per player (lower K-factor for established players, higher for new players)
- The Chess Game Viewer component should use a chess library (e.g., chess.js) as a static resource for move validation and board rendering
- The UI should support standard chess piece symbols using Unicode characters or SVG icons

## Glossary

- **ELO Rating**: A numerical rating system that calculates the relative skill levels of players in chess, developed by Arpad Elo
- **K-Factor**: A constant in the ELO formula that determines the maximum rating change per game (typically 32 for active players, 16 for masters)
- **Expected Score**: The probability of winning calculated from the rating difference between two players
- **PGN**: Portable Game Notation - a standard plain text format for recording chess games with move sequences
- **FEN**: Forsyth-Edwards Notation - a standard notation for describing a particular board position in chess
- **Draw**: A game that ends with neither player winning (both players receive 0.5 points)
- **Abandoned**: A game that was started but not completed properly (does not affect ratings)
- **Win Rate**: Percentage of games won, calculated as (Wins / Total Games) * 100
- **Algebraic Notation**: Standard chess notation for recording moves (e.g., E4, Nf3, O-O)