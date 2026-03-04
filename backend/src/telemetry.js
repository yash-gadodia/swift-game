export function sanitizeTelemetryEvent(payload, ipAddress = 'unknown') {
  const event = String(payload?.event || '').trim();
  if (!event || event.length > 64) {
    return { error: 'invalid_event' };
  }

  const rawTs = String(payload?.ts || '').trim();
  const parsedTs = new Date(rawTs);
  if (!rawTs || Number.isNaN(parsedTs.getTime())) {
    return { error: 'invalid_ts' };
  }

  const rawFields = payload?.fields;
  if (rawFields != null && (typeof rawFields !== 'object' || Array.isArray(rawFields))) {
    return { error: 'invalid_fields' };
  }

  const fields = {};
  const entries = Object.entries(rawFields || {});
  if (entries.length > 32) {
    return { error: 'too_many_fields' };
  }

  for (const [rawKey, rawValue] of entries) {
    const key = String(rawKey).trim();
    if (!key || key.length > 64) {
      return { error: 'invalid_field_key' };
    }

    const value = String(rawValue ?? '').slice(0, 256);
    fields[key] = value;
  }

  return {
    value: {
      event,
      ts: parsedTs.toISOString(),
      fields,
      ipAddress,
      ingestedAt: new Date().toISOString()
    }
  };
}
