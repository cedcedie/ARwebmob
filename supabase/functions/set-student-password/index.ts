// Supabase Edge Function: resets a student's Firebase Auth password.
// Replaces the Firebase Cloud Function `setStudentPassword` (needs paid Blaze).
//
// Secret required: FIREBASE_SERVICE_ACCOUNT (the service-account JSON).
// Caller sends their Firebase ID token in `x-firebase-token`; the Supabase
// anon key in Authorization/apikey only gets past the Supabase gateway.
import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from "npm:jose@5";

const BOOTSTRAP_TEACHER_EMAIL = "nadinevictoria17@gmail.com";
const STUDENT_EMAIL_PATTERN = /^[0-9]+@arscience\.school$/;
const MIN_PASSWORD_LENGTH = 6;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-firebase-token, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function reply(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

const account = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");
const projectId: string = account.project_id;

const firebaseKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

async function verifyCallerEmail(idToken: string): Promise<string> {
  try {
    const { payload } = await jwtVerify(idToken, firebaseKeys, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });
    const email = String(payload.email ?? "").toLowerCase();
    if (!email) throw new Error("no email");
    return email;
  } catch {
    throw new HttpError(401, "Sign in first.");
  }
}

async function adminAccessToken(): Promise<string> {
  const key = await importPKCS8(account.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/cloud-platform",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(account.client_email)
    .setSubject(account.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("55m")
    .sign(key);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`token exchange failed: ${res.status}`);
  return (await res.json()).access_token;
}

async function assertIsTeacher(email: string, token: string) {
  if (STUDENT_EMAIL_PATTERN.test(email)) {
    throw new HttpError(403, "Student accounts cannot do this.");
  }
  if (email === BOOTSTRAP_TEACHER_EMAIL) return;
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/teachers/${
      encodeURIComponent(email)
    }`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (res.status === 404) {
    throw new HttpError(403, "This account does not have teacher access.");
  }
  if (!res.ok) throw new Error(`teacher lookup failed: ${res.status}`);
}

async function identityToolkit(path: string, token: string, body: unknown) {
  return await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/${path}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    if (!projectId) throw new Error("FIREBASE_SERVICE_ACCOUNT is not set");
    const idToken = req.headers.get("x-firebase-token") ?? "";
    const callerEmail = await verifyCallerEmail(idToken);

    const data = await req.json().catch(() => ({}));
    const studentId = String(data.studentId ?? "").replace(/\D/g, "");
    const newPassword = String(data.newPassword ?? "");
    if (!studentId) throw new HttpError(400, "A student ID is required.");
    if (newPassword.length < MIN_PASSWORD_LENGTH) {
      throw new HttpError(
        400,
        `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`,
      );
    }

    const token = await adminAccessToken();
    await assertIsTeacher(callerEmail, token);

    const studentEmail = `${studentId}@arscience.school`;
    const lookup = await identityToolkit("accounts:lookup", token, {
      email: [studentEmail],
    });
    if (!lookup.ok) throw new Error(`lookup failed: ${lookup.status}`);
    const localId = (await lookup.json()).users?.[0]?.localId;
    if (!localId) {
      throw new HttpError(
        404,
        'This student has no login yet. Create one with "Create login" instead.',
      );
    }

    const update = await identityToolkit("accounts:update", token, {
      localId,
      password: newPassword,
    });
    if (!update.ok) throw new Error(`update failed: ${update.status}`);

    console.log(`[set-student-password] ${callerEmail} reset ${studentEmail}`);
    return reply(200, { ok: true });
  } catch (error) {
    if (error instanceof HttpError) {
      return reply(error.status, { error: error.message });
    }
    console.error(error);
    return reply(500, { error: "That did not work. Please try again." });
  }
});
