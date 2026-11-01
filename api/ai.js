// Endpoint AI Food Diary (Vercel Function, Node — tanpa dependensi).
//
// Menerima  : { "messages": [{role, content}, ...] }   (content boleh array
//             gaya OpenAI bila memuat {"type":"image_url"}).
// Membalas  : { "text": "..." }  atau  { "error": "..." }.
//
// Kunci AI hanya ada di sisi server (env NARA_API_KEY), tidak pernah ikut
// ke browser/HP. Model dipilih di sini: ada gambar -> qwen3.8-flash (terbukti
// bisa membaca foto), tanpa gambar -> glm-5.3-flash (murah).
//
// Pembatas sederhana: maks 30 permintaan / 10 menit / alamat IP (per instance
// server — cukup untuk menahan penyalahgunaan ringan di situs publik).

const UPSTREAM = "https://router.bynara.id/v1/chat/completions";
const MODEL_TEKS = "glm-5.3-flash";
const MODEL_VISION = "qwen3.8-flash";

const SISTEM_CHAT =
  "Kamu asisten makanan berbahasa Indonesia yang ramah dan praktis. " +
  "Jawab ringkas: maksimal 4 kalimat, langsung ke inti. Boleh menyebut " +
  "estimasi kalori bila relevan. Jangan memberi nasihat medis.";

const SISTEM_FOTO =
  "Identifikasi makanan pada foto. Balas HANYA JSON tanpa penjelasan lain, " +
  'format: {"nama":"...","porsi":"...","kalori":"..."} — nama sesingkat ' +
  "mungkin (2-4 kata), porsi dalam kata (mis. \"1 piring\"), kalori angka " +
  "dalam kkal. Bahasa Indonesia.";

const jendelaMs = 10 * 60 * 1000;
const batasMaks = 30;
const pengunjung = new Map();

function kenaBatas(ip) {
  const kini = Date.now();
  const arr = (pengunjung.get(ip) || []).filter((t) => kini - t < jendelaMs);
  arr.push(kini);
  if (pengunjung.size > 500) pengunjung.clear();
  pengunjung.set(ip, arr);
  return arr.length > batasMaks;
}

function adaGambar(messages) {
  return messages.some(
    (m) =>
      Array.isArray(m.content) &&
      m.content.some((c) => c && c.type === "image_url")
  );
}

module.exports = async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Gunakan POST" });

  const kunci = process.env.NARA_API_KEY;
  if (!kunci) return res.status(500).json({ error: "Kunci AI belum dipasang di server" });

  const ip =
    String(req.headers["x-forwarded-for"] || "").split(",")[0].trim() ||
    "lokal";
  if (kenaBatas(ip)) {
    return res.status(429).json({ error: "Terlalu banyak permintaan, coba sebentar lagi" });
  }

  let body = req.body;
  if (typeof body === "string") {
    try {
      body = JSON.parse(body);
    } catch {
      body = null;
    }
  }
  const messages = body && Array.isArray(body.messages) ? body.messages : null;
  if (!messages || messages.length === 0 || messages.length > 20) {
    return res.status(400).json({ error: "messages tidak valid" });
  }

  const vision = adaGambar(messages);
  const dipakai = vision ? MODEL_VISION : MODEL_TEKS;
  const pesan = vision
    ? [{ role: "system", content: SISTEM_FOTO }, ...messages.slice(-2)]
    : [{ role: "system", content: SISTEM_CHAT }, ...messages.slice(-12)];

  try {
    const r = await fetch(UPSTREAM, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer " + kunci,
      },
      body: JSON.stringify({
        model: dipakai,
        messages: pesan,
        max_tokens: vision ? 220 : 400,
        temperature: 0.6,
      }),
    });
    const j = await r.json().catch(() => null);
    if (!r.ok) {
      const sebab =
        (j && ((j.error && j.error.message) || j.message)) || "HTTP " + r.status;
      return res
        .status(502)
        .json({ error: "AI gagal menjawab: " + String(sebab).slice(0, 200) });
    }
    const teks = j && j.choices && j.choices[0] && j.choices[0].message
      ? j.choices[0].message.content
      : null;
    if (!teks) return res.status(502).json({ error: "AI tidak mengirim jawaban" });
    return res.status(200).json({ text: String(teks), model: dipakai });
  } catch (e) {
    return res
      .status(502)
      .json({ error: "Tidak bisa menghubungi AI: " + String(e).slice(0, 160) });
  }
};
