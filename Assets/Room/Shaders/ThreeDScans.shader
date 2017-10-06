Shader "Room/ThreeDScans"
{
    Properties
    {
        // Render mode options
        [KeywordEnum(Default, Helix)] 
        _Mode("", Float) = 0

        // Base maps
        _NormalMap("", 2D) = "bump" {}
        _OcclusionMap("", 2D) = "white" {}
        _OcclusionMapStrength("", Range(0, 1)) = 1
        _CurvatureMap("", 2D) = "white" {}

        // Channel 1
        _Color1("", Color) = (1, 1, 1, 1)
        _Smoothness1("", Range(0, 1)) = 0
        [Gamma] _Metallic1("", Range(0, 1)) = 0

        // Channel 2
        _Color2("", Color) = (1, 1, 1, 1)
        _Smoothness2("", Range(0, 1)) = 0
        [Gamma] _Metallic2("", Range(0, 1)) = 0

        // Channel 3 (backface)
        _Color3("", Color) = (1, 0, 0, 0)
        _Smoothness3("", Range(0, 1)) = 0
        [Gamma] _Metallic3("", Range(0, 1)) = 0

        // Detail maps
        _DetailAlbedoMap("", 2D) = "gray" {}
        _DetailNormalMap("", 2D) = "bump" {}
        _DetailNormalMapScale("", Range(0, 2)) = 1
        _DetailMapScale("", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Cull off

        CGPROGRAM

        #pragma surface Surface Standard vertex:Vertex addshadow nolightmap exclude_path:forward
        #pragma multi_compile _MODE_DEFAULT _MODE_HELIX
        #pragma target 3.0

        struct Input
        {
            float2 texCoord;
            float3 localCoord;
            float3 localNormal;
            float vface : VFACE;
        };

        sampler2D _NormalMap;
        sampler2D _OcclusionMap;
        half _OcclusionMapStrength;
        sampler2D _CurvatureMap;

        half3 _Color1;
        half3 _Color2;
        half3 _Color3;

        half _Metallic1;
        half _Metallic2;
        half _Metallic3;

        half _Smoothness1;
        half _Smoothness2;
        half _Smoothness3;

        sampler2D _DetailAlbedoMap;
        sampler2D _DetailNormalMap;
        half _DetailNormalMapScale;
        half _DetailMapScale;

        void Vertex(inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);
            data.texCoord = v.texcoord.xy;
            data.localCoord = v.vertex.xyz;
            data.localNormal = v.normal.xyz;
        }

        void Surface(Input IN, inout SurfaceOutputStandard o)
        {
#if defined(_MODE_HELIX)
            float phi = atan2(IN.localCoord.z, IN.localCoord.x);
            clip(frac(IN.localCoord.y * 8 + phi / UNITY_PI) - 0.5);
#endif

            // Surface flip
            float flip = IN.vface < 0 ? 1 : 0;

            // Curvature map
            half cv = tex2D(_CurvatureMap, IN.texCoord).g;
            cv = pow(cv, 12);

            // Triplanar mapping
            float3 tc = IN.localCoord * _DetailMapScale;

            // Blend factor of triplanar mapping
            float3 bf = abs(IN.localNormal);
            bf /= dot(bf, 1);

            // Base color
            half3 am = tex2D(_DetailAlbedoMap, tc.yz).rgb * bf.x +
                       tex2D(_DetailAlbedoMap, tc.zx).rgb * bf.y +
                       tex2D(_DetailAlbedoMap, tc.xy).rgb * bf.z;
            o.Albedo = lerp(lerp(_Color1, _Color2, cv), _Color3, flip) * am;

            // Normal map
            half3 nb = UnpackNormal(tex2D(_NormalMap, IN.texCoord));
            half4 ns = tex2D(_DetailNormalMap, tc.yz) * bf.x +
                       tex2D(_DetailNormalMap, tc.zx) * bf.y +
                       tex2D(_DetailNormalMap, tc.xy) * bf.z;
            half3 nm = UnpackScaleNormal(ns, _DetailNormalMapScale);
            o.Normal = BlendNormals(nb, nm) * (1 - flip * 2);

            // Occlusion map
            half occ = tex2D(_OcclusionMap, IN.texCoord).g;
            o.Occlusion = LerpOneTo(occ, _OcclusionMapStrength);

            // Etc.
            o.Metallic = lerp(_Metallic1, _Metallic2, cv);
            o.Smoothness = lerp(_Smoothness1, _Smoothness2, cv);
        }

        ENDCG
    }

    FallBack "Diffuse"
    CustomEditor "Room.ThreeDScansMaterialInspector"
}
