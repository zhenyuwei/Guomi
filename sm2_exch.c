/* 	pms, &pmslen, ---out info
	EC_KEY_get0_public_key(peer_ephem),  ---peer temp key Rb
	ephem, ---local temp key
	EC_KEY_get0_public_key(peer_pk), ---local peer cert key Ra
	sk, ---local cert key
	initiator = 0
*/
int SM2_compute_share_key(unsigned char *out, size_t *outlen,
	const EC_KEY *peer_ephem, EC_KEY *ephem,
	const EC_KEY *peer_pk, EC_KEY *sk, int initiator)
{
	int ret = 0;
	SM2_KAP_CTX ctx;
	const BIGNUM *prikey;
	BIGNUM *h = NULL, *x = NULL;
	unsigned char ephem_point[128] = {0};
	size_t ephem_point_len = sizeof(ephem_point);

	memset(&ctx, 0, sizeof(ctx));

	/* last param is 0 (do_checksum) donot check S in key agreement, S no send to check others */
	if (!SM2_KAP_CTX_init(&ctx, sk, SM2_DEFAULT_ID, 16, peer_pk, SM2_DEFAULT_ID, 16, initiator, 0)) {
		ECerr(EC_F_SM2_KAP_CTX_INIT, ERR_R_INIT_FAIL);
		goto end;
	}

	/* get private key */
	if (!(prikey = EC_KEY_get0_private_key(ctx.ec_key))) {
		ECerr(EC_F_SM2_KAP_PREPARE, EC_R_SM2_KAP_NOT_INITED);
		return 0;
	}

	h = BN_new();
	x = BN_new();

	if (!h || !x) {
		ECerr(EC_F_SM2_KAP_PREPARE, 0);
		goto end;
	}

	if (EC_METHOD_get_field_type(EC_GROUP_method_of(ctx.group)) == NID_X9_62_prime_field) {
		if (!EC_POINT_get_affine_coordinates_GFp(ctx.group, EC_KEY_get0_public_key(ephem), x, NULL, ctx.bn_ctx)) {
			ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_EC_LIB);
			goto end;
		}
	} else {
		if (!EC_POINT_get_affine_coordinates_GF2m(ctx.group, EC_KEY_get0_public_key(ephem), x, NULL, ctx.bn_ctx)) {
			ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_EC_LIB);
			goto end;
		}
	}

	/*
	 * w = ceil(keybits / 2) - 1
	 * x = 2^w + (x and (2^w - 1)) = 2^w + (x mod 2^w)
	 * t = (d + x * r) mod n
	 * t = (h * t) mod n
	 */
	if (!ctx.t) {
		ECerr(EC_F_SM2_KAP_PREPARE, EC_R_SM2_KAP_NOT_INITED);
		goto end;
	}

	/* step A4 | step B3 */
	if (!BN_nnmod(x, x, ctx.two_pow_w, ctx.bn_ctx)) {/* ctx->two_pow_w = 2^w   x mod 2^w */
		ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_BN_LIB);
		goto end;
	}
	if (!BN_add(x, x, ctx.two_pow_w)) {/* x = 2^w + (x and (2^w - 1)) = 2^w + (x mod 2^w) */
		ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_BN_LIB);
		goto end;
	}

	/* step A5 | step B4 */
	if (!BN_mod_mul(ctx.t, x, EC_KEY_get0_private_key(ephem), ctx.order, ctx.bn_ctx)) {/* t = ( x * r) mod n */
		ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_BN_LIB);
		goto end;
	}
	if (!BN_mod_add(ctx.t, ctx.t, prikey, ctx.order, ctx.bn_ctx)) {/* t = (d + x * r) mod n */
		ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_BN_LIB);
		goto end;
	}

	if (!EC_GROUP_get_cofactor(ctx.group, h, ctx.bn_ctx)) {/* h */
		ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_EC_LIB);
		goto end;
	}

	if (!BN_mul(ctx.t, ctx.t, h, ctx.bn_ctx)) { /* t = (h * t) mod n */
		ECerr(EC_F_SM2_KAP_PREPARE, ERR_R_BN_LIB);
		goto end;
	}

	/* encode R = (x, y) for output and local buffer */
	/* FIXME: ret is size_t and ret is the output length */
	ret = EC_POINT_point2oct(ctx.group, EC_KEY_get0_public_key(peer_ephem), ctx.point_form,
		ephem_point, ephem_point_len, ctx.bn_ctx);

	memcpy(ctx.pt_buf, ephem_point, ret);
	ephem_point_len = ret;
	
	ret = 0;

	
	if (!SM2_KAP_compute_key(&ctx, ephem_point, ephem_point_len, out, *outlen, NULL, 0)) {
		ECerr(EC_F_SM2_KAP_COMPUTE_KEY, ERR_R_KDF2_LIB);
		goto end;
	}
	
	ret = 1;
	
end:
	
	SM2_KAP_CTX_cleanup(&ctx);
	if (h) BN_free(h);
	if (x) BN_free(x);
	
	return ret;
}