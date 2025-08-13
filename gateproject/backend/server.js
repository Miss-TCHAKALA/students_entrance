 require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');
const WebSocket = require('ws');
const http = require('http');

const app = express();
app.use(cors({ origin: '*' })); // ✅ Allow all origins
app.use(bodyParser.json());

// Serveur Express + WebSocket
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

wss.on('connection', ws => {
    console.log('✅ Client WebSocket connecté');
    ws.send('Bienvenue sur le WebSocket !');

    ws.on('message', message => {
        console.log(`📩 Message reçu : ${message}`);
    });

    ws.on('close', () => {
        console.log('❌ Client WebSocket déconnecté');
    });
});

// Connexion MySQL
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'school_gatekeeper',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// ✅ Ajouter un étudiant
app.post('/add-student', async (req, res) => {
    const { student_id, name, profile_image, qr_code } = req.body;
    if (!student_id || !name || !profile_image || !qr_code) {
        return res.status(400).json({ error: 'Tous les champs sont obligatoires' });
    }

    try {
        const sql = 'INSERT INTO students (student_id, name, profile_image, qr_code) VALUES (?, ?, ?, ?)';
        await pool.promise().execute(sql, [student_id, name, profile_image, qr_code]);

        wss.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify({ message: 'Nouvel étudiant ajouté', student_id, name }));
            }
        });

        res.status(201).json({ message: '✅ Étudiant ajouté avec succès' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ✅ Récupérer tous les étudiants
app.get('/students', async (req, res) => {
    try {
        const [results] = await pool.promise().execute('SELECT * FROM students');
        res.json(results);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ✅ Récupérer un étudiant par ID
app.get('/student/:student_id', async (req, res) => {
    const { student_id } = req.params;
    try {
        const [results] = await pool.promise().execute('SELECT * FROM students WHERE student_id = ?', [student_id]);
        if (results.length > 0) {
            res.json(results[0]);
        } else {
            res.status(404).json({ error: 'Étudiant non trouvé' });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ✅ Mettre à jour un étudiant
app.put('/student/:student_id', async (req, res) => {
    const { student_id } = req.params;
    const { name, profile_image, qr_code } = req.body;

    try {
        const sql = 'UPDATE students SET name = ?, profile_image = ?, qr_code = ? WHERE student_id = ?';
        const [result] = await pool.promise().execute(sql, [name, profile_image, qr_code, student_id]);

        if (result.affectedRows > 0) {
            wss.clients.forEach(client => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify({ message: 'Étudiant mis à jour', student_id, name }));
                }
            });
            res.json({ message: '✅ Étudiant mis à jour avec succès' });
        } else {
            res.status(404).json({ error: 'Étudiant non trouvé' });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ✅ Supprimer un étudiant
app.delete('/student/:student_id', async (req, res) => {
    const { student_id } = req.params;

    try {
        const sql = 'DELETE FROM students WHERE student_id = ?';
        const [result] = await pool.promise().execute(sql, [student_id]);

        if (result.affectedRows > 0) {
            wss.clients.forEach(client => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify({ message: 'Étudiant supprimé', student_id }));
                }
            });
            res.json({ message: '✅ Étudiant supprimé avec succès' });
        } else {
            res.status(404).json({ error: 'Étudiant non trouvé' });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// 🚀 Démarrage du serveur
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 Serveur HTTP et WebSocket en cours d'exécution sur http://localhost:${PORT}`);
});