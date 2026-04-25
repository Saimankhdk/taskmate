const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();

const smtpHost = defineSecret("SMTP_HOST");
const smtpPort = defineSecret("SMTP_PORT");
const smtpUser = defineSecret("SMTP_USER");
const smtpPass = defineSecret("SMTP_PASS");
const smtpFrom = defineSecret("SMTP_FROM");

const resetContinueUrl = defineSecret("RESET_CONTINUE_URL");
const appDisplayName = defineSecret("APP_DISPLAY_NAME");

function isValidEmail(email) {
  return typeof email === "string" && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function buildResetEmailHtml({resetLink, appName}) {
  return `
    <div style="font-family:Arial,Helvetica,sans-serif;line-height:1.5;color:#111827;">
      <p>Hello,</p>
      <p>You requested to reset your password for ${appName}.</p>
      <p style="margin:24px 0;">
        <a href="${resetLink}" style="background:#5B5CEB;color:#FFFFFF;text-decoration:none;padding:12px 20px;border-radius:10px;display:inline-block;font-weight:600;">
          Reset Password
        </a>
      </p>
      <p>If you did not request this, you can safely ignore this email.</p>
      <p>Thanks,<br/>${appName} Team</p>
    </div>
  `;
}

function buildResetEmailText({resetLink, appName}) {
  return [
    "Hello,",
    "",
    `You requested to reset your password for ${appName}.`,
    "",
    `Reset your password: ${resetLink}`,
    "",
    "If you did not request this, you can safely ignore this email.",
    "",
    `Thanks,`,
    `${appName} Team`,
  ].join("\n");
}

function buildInviteReplyHtml({title, body}) {
  return `
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <title>${title}</title>
      </head>
      <body style="font-family:Arial,Helvetica,sans-serif;background:#F9FAFB;color:#111827;padding:24px;">
        <div style="max-width:520px;margin:0 auto;background:#fff;border:1px solid #E5E7EB;border-radius:14px;padding:20px;">
          <h2 style="margin:0 0 10px 0;">${title}</h2>
          <p style="margin:0;line-height:1.55;">${body}</p>
        </div>
      </body>
    </html>
  `;
}

function buildInviteLinks({
  projectId,
  inviteId,
  token,
}) {
  const baseUrl = `https://us-central1-${projectId}.cloudfunctions.net/respondWorkspaceInvite`;
  const acceptUrl =
    `${baseUrl}?inviteId=${encodeURIComponent(inviteId)}` +
    `&token=${encodeURIComponent(token)}&action=accept`;
  const declineUrl =
    `${baseUrl}?inviteId=${encodeURIComponent(inviteId)}` +
    `&token=${encodeURIComponent(token)}&action=decline`;
  return {acceptUrl, declineUrl};
}

function buildInviteEmailHtml({
  appName,
  workspaceName,
  joinCode,
  inviterName,
  acceptUrl,
  declineUrl,
}) {
  return [
    `<div style="font-family:Arial,Helvetica,sans-serif;line-height:1.5;color:#111827;">`,
    `<p>Hello,</p>`,
    `<p><strong>${inviterName || "Your teammate"}</strong> invited you to join <strong>${workspaceName}</strong> on ${appName}.</p>`,
    `<p>Use workspace code: <strong>${joinCode}</strong></p>`,
    `<p style="margin:24px 0;">`,
    `<a href="${acceptUrl}" style="background:#10B981;color:#FFFFFF;text-decoration:none;padding:10px 16px;border-radius:8px;display:inline-block;font-weight:600;margin-right:8px;">Accept invite</a>`,
    `<a href="${declineUrl}" style="background:#EF4444;color:#FFFFFF;text-decoration:none;padding:10px 16px;border-radius:8px;display:inline-block;font-weight:600;">Decline invite</a>`,
    `</p>`,
    `<p>If the buttons do not work, open this link to accept: <br/><a href="${acceptUrl}">${acceptUrl}</a></p>`,
    `<p>Thanks,<br/>${appName} Team</p>`,
    `</div>`,
  ].join("");
}

function buildInviteEmailText({
  appName,
  workspaceName,
  joinCode,
  inviterName,
  acceptUrl,
  declineUrl,
}) {
  return [
    "Hello,",
    "",
    `${inviterName || "Your teammate"} invited you to join "${workspaceName}" on ${appName}.`,
    `Workspace code: ${joinCode}`,
    "",
    `Accept invite: ${acceptUrl}`,
    `Decline invite: ${declineUrl}`,
    "",
    `Thanks,`,
    `${appName} Team`,
  ].join("\n");
}

exports.requestPasswordReset = onRequest(
  {
    region: "us-central1",
    secrets: [
      smtpHost,
      smtpPort,
      smtpUser,
      smtpPass,
      smtpFrom,
      resetContinueUrl,
      appDisplayName,
    ],
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed."});
      return;
    }

    const email = (req.body?.email || "").toString().trim().toLowerCase();
    if (!isValidEmail(email)) {
      res.status(400).json({error: "Enter a valid email address."});
      return;
    }

    const appName = appDisplayName.value() || "TaskMate";
    const continueUrl =
      resetContinueUrl.value() || "https://taskmate-chat-test.firebaseapp.com";

    const transporter = nodemailer.createTransport({
      host: smtpHost.value(),
      port: Number.parseInt(smtpPort.value(), 10) || 587,
      secure: Number.parseInt(smtpPort.value(), 10) === 465,
      auth: {
        user: smtpUser.value(),
        pass: smtpPass.value(),
      },
    });

    try {
      const resetLink = await admin.auth().generatePasswordResetLink(email, {
        url: continueUrl,
      });

      const html = buildResetEmailHtml({resetLink, appName});
      const text = buildResetEmailText({resetLink, appName});

      await transporter.sendMail({
        from: smtpFrom.value(),
        to: email,
        subject: `Reset your ${appName} password`,
        text,
        html,
      });
    } catch (err) {
      // Avoid user enumeration: return success when user doesn't exist.
      if (err?.code !== "auth/user-not-found") {
        console.error("Password reset email send failed:", err);
        res.status(500).json({
          error: "Could not send reset email. Please try again.",
        });
        return;
      }
    }

    res.status(200).json({
      message: "If an account exists for that email, a reset email was sent.",
    });
  },
);

exports.sendWorkspaceInviteEmail = onRequest(
  {
    region: "us-central1",
    secrets: [smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, appDisplayName],
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed."});
      return;
    }

    const projectId = process.env.GCLOUD_PROJECT || "";
    const inviteId = (req.body?.inviteId || "").toString().trim();
    const token = (req.body?.token || "").toString().trim();
    const email = (req.body?.email || "").toString().trim().toLowerCase();
    const workspaceName = (req.body?.workspaceName || "Workspace")
        .toString()
        .trim();
    const joinCode = (req.body?.joinCode || "").toString().trim().toUpperCase();
    const inviterName = (req.body?.inviterName || "Your teammate")
        .toString()
        .trim();

    if (!inviteId || !token || !email || !joinCode || !projectId) {
      res.status(400).json({error: "Missing required invite payload."});
      return;
    }
    if (!isValidEmail(email)) {
      res.status(400).json({error: "Enter a valid email address."});
      return;
    }

    try {
      const {acceptUrl, declineUrl} = buildInviteLinks({
        projectId,
        inviteId,
        token,
      });
      const appName = appDisplayName.value() || "TaskMate";
      const transporter = nodemailer.createTransport({
        host: smtpHost.value(),
        port: Number.parseInt(smtpPort.value(), 10) || 587,
        secure: Number.parseInt(smtpPort.value(), 10) === 465,
        auth: {
          user: smtpUser.value(),
          pass: smtpPass.value(),
        },
      });
      const html = buildInviteEmailHtml({
        appName,
        workspaceName,
        joinCode,
        inviterName,
        acceptUrl,
        declineUrl,
      });
      const text = buildInviteEmailText({
        appName,
        workspaceName,
        joinCode,
        inviterName,
        acceptUrl,
        declineUrl,
      });
      await transporter.sendMail({
        from: smtpFrom.value(),
        to: email,
        subject: `You're invited to join ${workspaceName} on ${appName}`,
        text,
        html,
      });
      await admin.firestore().collection("groupInvites").doc(inviteId).set({
        emailStatus: "sent",
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      res.status(200).json({ok: true});
    } catch (err) {
      console.error("sendWorkspaceInviteEmail failed:", err);
      await admin.firestore().collection("groupInvites").doc(inviteId).set({
        emailStatus: "failed",
        emailError: err?.message || "Email send failed",
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      res.status(500).json({error: "Failed to send email invite."});
    }
  },
);

exports.respondWorkspaceInvite = onRequest(
  {
    region: "us-central1",
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).send("Method not allowed.");
      return;
    }

    const inviteId = (req.query?.inviteId || "").toString().trim();
    const token = (req.query?.token || "").toString().trim();
    const action = (req.query?.action || "").toString().trim().toLowerCase();
    if (!inviteId || !token || !["accept", "decline"].includes(action)) {
      res.status(400).send(buildInviteReplyHtml({
        title: "Invalid invite link",
        body: "This invite link is invalid or incomplete.",
      }));
      return;
    }

    const inviteRef = admin.firestore().collection("groupInvites").doc(inviteId);
    const inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) {
      res.status(404).send(buildInviteReplyHtml({
        title: "Invite not found",
        body: "This invite may have expired or already been removed.",
      }));
      return;
    }

    const invite = inviteSnap.data() || {};
    const expiresAt = invite.expiresAt?.toDate?.();
    if (invite.token !== token) {
      res.status(403).send(buildInviteReplyHtml({
        title: "Invite rejected",
        body: "The security token on this invite is invalid.",
      }));
      return;
    }
    if (invite.status && invite.status !== "pending") {
      res.status(200).send(buildInviteReplyHtml({
        title: "Invite already handled",
        body: `This invite was already marked as "${invite.status}".`,
      }));
      return;
    }
    if (expiresAt && expiresAt.getTime() < Date.now()) {
      await inviteRef.set({
        status: "expired",
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      res.status(410).send(buildInviteReplyHtml({
        title: "Invite expired",
        body: "This invite has expired. Ask your workspace admin for a new one.",
      }));
      return;
    }

    if (action === "decline") {
      await inviteRef.set({
        status: "declined",
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      res.status(200).send(buildInviteReplyHtml({
        title: "Invite declined",
        body: "You declined this workspace invite.",
      }));
      return;
    }

    const groupId = (invite.groupId || "").toString().trim();
    const groupRef = admin.firestore().collection("groups").doc(groupId);
    await admin.firestore().runTransaction(async (tx) => {
      const groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw new Error("group-not-found");
      }

      const group = groupSnap.data() || {};
      const members = Array.isArray(group.members) ? [...group.members] : [];
      const memberUids = Array.isArray(group.memberUids) ? [...group.memberUids] : [];
      const inviteeUid = (invite.inviteeUid || "").toString().trim();
      const invitePhone = (invite.phone || "").toString().trim();
      const inviteEmail = (invite.email || "").toString().trim().toLowerCase();
      const inviteLabel = invitePhone || inviteEmail;
      const alreadyMember = members.some((m) => {
        return (inviteeUid && m.userId === inviteeUid) ||
          (inviteLabel && m.phone === inviteLabel);
      });

      if (!alreadyMember) {
        members.push({
          name: invite.inviteeName || inviteLabel || "New member",
          phone: inviteLabel,
          isAdmin: false,
          isAppUser: !!inviteeUid,
          ...(inviteeUid ? {userId: inviteeUid} : {}),
        });
      }
      if (inviteeUid && !memberUids.includes(inviteeUid)) {
        memberUids.push(inviteeUid);
      }

      tx.set(groupRef, {members, memberUids}, {merge: true});
      tx.set(inviteRef, {
        status: "accepted",
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    });

    res.status(200).send(buildInviteReplyHtml({
      title: "Invite accepted",
      body:
        "You accepted this workspace invite. Open TaskMate and use the workspace join code if prompted.",
    }));
  },
);
