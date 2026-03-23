import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGameById from '@salesforce/apex/CHE_ChessGameViewerController.getGameById';
import getAllGames from '@salesforce/apex/CHE_ChessGameViewerController.getAllGames';

/**
 * Chess Game Viewer Component
 * Displays an interactive chess board with game information, player details, and move history
 */
export default class ChessGameViewer extends LightningElement {
    @api recordId; // When used on a record page
    @track selectedGameId = '';
    @track currentGame = null;
    @track errorMessage = '';
    @track gameList = [];
    @track boardSquares = [];

    // Unicode chess pieces
    chessPieces = {
        'K': '♔', // White King
        'Q': '♕', // White Queen
        'R': '♖', // White Rook
        'B': '♗', // White Bishop
        'N': '♘', // White Knight
        'P': '♙', // White Pawn
        'k': '♚', // Black King
        'q': '♛', // Black Queen
        'r': '♜', // Black Rook
        'b': '♝', // Black Bishop
        'n': '♞', // Black Knight
        'p': '♟'  // Black Pawn
    };

    /**
     * Initialize component on load
     */
    connectedCallback() {
        this.loadGameList();
        if (this.recordId) {
            this.selectedGameId = this.recordId;
            this.loadGame(this.recordId);
        } else {
            this.initializeEmptyBoard();
        }
    }

    /**
     * Load list of all games for dropdown
     */
    loadGameList() {
        getAllGames()
            .then(result => {
                this.gameList = result || [];
            })
            .catch(error => {
                this.handleError('Error loading games', error);
            });
    }

    /**
     * Get game options for combobox
     */
    get gameOptions() {
        return this.gameList.map(game => ({
            label: `${game.gameName} - ${game.whitePlayerName} vs ${game.blackPlayerName}`,
            value: game.gameId
        }));
    }

    /**
     * Handle game selection from dropdown
     */
    handleGameSelect(event) {
        const gameId = event.detail.value;
        if (gameId) {
            this.selectedGameId = gameId;
            this.loadGame(gameId);
        }
    }

    /**
     * Load game data and render board
     */
    loadGame(gameId) {
        this.errorMessage = '';
        getGameById({ gameId: gameId })
            .then(result => {
                if (result) {
                    this.currentGame = result;
                    this.renderBoard();
                } else {
                    this.errorMessage = 'Game not found';
                    this.currentGame = null;
                }
            })
            .catch(error => {
                this.handleError('Error loading game', error);
                this.currentGame = null;
            });
    }

    /**
     * Initialize empty chess board
     */
    initializeEmptyBoard() {
        const squares = [];
        for (let rank = 8; rank >= 1; rank--) {
            for (let file = 0; file < 8; file++) {
                const fileChar = String.fromCharCode(65 + file); // A-H
                const isLight = (rank + file) % 2 === 0;
                squares.push({
                    id: `${fileChar}${rank}`,
                    notation: `${fileChar}${rank}`,
                    class: `square ${isLight ? 'light' : 'dark'}`,
                    piece: ''
                });
            }
        }
        this.boardSquares = squares;
    }

    /**
     * Render chess board from FEN position or starting position
     */
    renderBoard() {
        const fen = this.currentGame.currentPositionFEN || 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
        const boardPosition = this.parseFEN(fen);
        const squares = [];

        for (let rank = 8; rank >= 1; rank--) {
            for (let file = 0; file < 8; file++) {
                const fileChar = String.fromCharCode(65 + file); // A-H
                const squareKey = `${fileChar.toLowerCase()}${rank}`;
                const isLight = (rank + file) % 2 === 0;

                const piece = boardPosition[squareKey] || '';
                const pieceChar = piece ? this.chessPieces[piece] : '';

                squares.push({
                    id: `${fileChar}${rank}`,
                    notation: `${fileChar}${rank}`,
                    class: `square ${isLight ? 'light' : 'dark'}`,
                    piece: pieceChar
                });
            }
        }

        this.boardSquares = squares;
    }

    /**
     * Parse FEN notation to board position
     */
    parseFEN(fen) {
        const position = {};
        const fenParts = fen.split(' ');
        const rows = fenParts[0].split('/');

        for (let rank = 0; rank < 8; rank++) {
            const row = rows[rank];
            let file = 0;

            for (let i = 0; i < row.length; i++) {
                const char = row[i];

                if (isNaN(char)) {
                    // It's a piece
                    const fileChar = String.fromCharCode(97 + file); // a-h
                    const actualRank = 8 - rank;
                    position[`${fileChar}${actualRank}`] = char;
                    file++;
                } else {
                    // It's a number of empty squares
                    file += parseInt(char, 10);
                }
            }
        }

        return position;
    }

    /**
     * Handle errors and show toast
     */
    handleError(title, error) {
        this.errorMessage = error.body ? error.body.message : error.message;
        const event = new ShowToastEvent({
            title: title,
            message: this.errorMessage,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }
}
