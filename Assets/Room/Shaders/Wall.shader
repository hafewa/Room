Shader "Room/Wall"
{
    Properties
    {
        // Render mode options
        [KeywordEnum(Default, Wave, Stripe)] 
        _Mode("", Float) = 0

        // Base parameters
        _Color1("", Color) = (1, 1, 1, 1)
        _Color2("", Color) = (1, 1, 1, 1)
        [Gamma] _Metallic("", Range(0, 1)) = 0
        _Smoothness("", Range(0, 1)) = 0

        // Base maps
        _NormalMap("", 2D) = "bump" {}
        _OcclusionMap("", 2D) = "white" {}
        _OcclusionMapStrength("", Range(0, 1)) = 1

        // Detail maps
        _DetailNormalMap("", 2D) = "bump" {}
        _DetailNormalMapScale("", Range(0, 2)) = 1
        _DetailMapScale("", Float) = 1
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    // Hash function from H. Schechter & R. Bridson, goo.gl/RXiKaH
    uint Hash(uint s)
    {
        s ^= 2747636419u;
        s *= 2654435769u;
        s ^= s >> 16;
        s *= 2654435769u;
        s ^= s >> 16;
        s *= 2654435769u;
        return s;
    }

    float Random(uint seed)
    {
        return float(Hash(seed)) / 4294967295.0; // 2^32-1
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off

        CGPROGRAM

        #pragma surface Surface Standard addshadow nolightmap exclude_path:forward
        #pragma multi_compile _MODE_DEFAULT _MODE_WAVE _MODE_STRIPE
        #pragma target 3.0

        struct Input
        {
            float2 uv_NormalMap;
            float3 worldPos;
        };

        half3 _Color1;
        half3 _Color2;
        half _Metallic;
        half _Smoothness;

        sampler2D _NormalMap;
        sampler2D _OcclusionMap;
        half _OcclusionMapStrength;

        sampler2D _DetailNormalMap;
        half _DetailNormalMapScale;
        half _DetailMapScale;

        float4x4 _WorldToEffect;
        float _LocalTime;
        float _Threshold;
        float4 _Params;

        void Surface(Input IN, inout SurfaceOutputStandard o)
        {
            float3 fx = mul(_WorldToEffect, float4(IN.worldPos, 1)).xyz;

#if defined(_MODE_WAVE)
            float p = frac(fx.z * _Params.x + sin(fx.y * _Params.y + _LocalTime));
            p = smoothstep(1, 1.01, 2 * abs(p - 0.5) + _Threshold);
            o.Albedo = lerp(_Color1, _Color2, p);
#elif defined(_MODE_STRIPE)
            float p = frac(fx.z * _Params.x + _LocalTime);
            p = smoothstep(1, 1.01, 2 * abs(p - 0.5) + _Threshold);
            o.Albedo = lerp(_Color1, _Color2, p);
#else
            o.Albedo = _Color1;
#endif

            float2 uv1 = IN.uv_NormalMap;
            float2 uv2 = uv1 * _DetailMapScale;

            half4 n1 = tex2D(_NormalMap, uv1);
            half4 n2 = tex2D(_DetailNormalMap, uv2);
            o.Normal = BlendNormals(
                UnpackNormal(n1),
                UnpackScaleNormal(n2, _DetailNormalMapScale)
            );

            half occ = tex2D(_OcclusionMap, uv1).g;
            o.Occlusion = LerpOneTo(occ, _OcclusionMapStrength);

            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
        }

        ENDCG
    }

    CustomEditor "Room.WallMaterialInspector"
    FallBack "Diffuse"
}
