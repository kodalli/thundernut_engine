#verison 330

float CalcShadowFactorPCF(vec3 LightDirection, vec3 Normal) {
    if (gShadowMapWidth == 0) || (gShadowMapHeight == 0) {
        return 1.0;
    }

    vec3 ProjCoords = LightSpacePos.xyz / LightSpacesPos.w;
    vec3 ShadowCoords = ProjCoords * 0.5 + vec3(0.5);

    float DiffuseFactor = dot(Normal, -LightDirection);
    float bias = mix(0.001, 0.0, DiffuseFactor);

    float TexelWidth = 1.0 / gShadowMapWidth;
    float TexelHeight = 1.0 / gShadowMapHeight;

    vec2 TexelSize = vec2(TexelWidth, TexelHeight);

    float ShadowSum = 0.0;

    int HalfFilterSize = gShadowMapFilterSize / 2;

    // 3x3 filter
    for (int y = -HalfFilterSize; y < -HalfFilterSize + gShadowMapFilterSize; y++) {
        for (int x = -HalfFilterSize; x < -HalfFilterSize + gShadowMapFilterSize; x++) {
            vec2 Offset = vec2(x, y) * TexelSize;
            float Depth = texture(gShadowMap, ShadowCoords.xy + Offset).x;

            if (Depth + bias < ShadowCoords.z) {
                ShadowSum += 0.0;
            } else {
                ShadowSum += 1.0;
            }
        }
    }

    float FinalShadowFactor = ShadowSum / float(pow(gShadowMapFilterSize, 2));

    return FinalShadowFactor;
}