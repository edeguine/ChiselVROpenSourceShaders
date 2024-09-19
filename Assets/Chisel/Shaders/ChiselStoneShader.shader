Shader "Custom/ChiselStoneShader"
    {
        Properties
        {
                _AlbedoColor ("Albedo Color", Color) = (1,1,1,1)
                _AmbientColor ("Ambient Color", Color) = (1,1,1,1)
                _AlbedaFactor("Albedo Factor", Range(0, 1)) = 0.5
                _AmbientFactor("Ambient Factor", Range(0, 1)) = 0.5
                _BumpMapSampler("Bump Map", 2D) = "black" {}
                _BumpScale("Bump Scale", Range(0, 5)) = 0.5
                _ContrastCorrection("Contrast Correction", Range(0, 1)) = 0
        }
	SubShader
	{
        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile_instancing

            #pragma vertex Vert
            #pragma fragment Frag
            #pragma require geometry
            
            
            float4 _AlbedoColor;
            float4 _AmbientColor;
            float _AlbedaFactor;
            float _AmbientFactor;
            float _ContrastCorrection;

            sampler2D _BumpMapSampler;
            float _BumpScale;


            
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texCoord : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            struct Varyings
            {
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float2 texCoord : TEXCOORD0;
                float4 clipPos : SV_POSITION;

                UNITY_VERTEX_OUTPUT_STEREO // make work in VR
            };

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                UNITY_SETUP_INSTANCE_ID(IN); 
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.texCoord = IN.texCoord;
                OUT.clipPos = TransformObjectToHClip(IN.positionOS);
                return OUT;
            }
            

            float dotProductTo01(float3 a, float3 b)
            {
                return max(0.05, dot(a, b));
            }

            // Fragment Shader
            float4 Frag(Varyings IN) : SV_Target
            {   
                // use this for hard edges / poly look
                float3 bumpNormal;
                bumpNormal = tex2D(_BumpMapSampler, IN.texCoord).rgb * 2.0 - 1.0;
                 
                float3 normal = normalize((IN.normalWS + bumpNormal * _BumpScale) / 2.0);

                float3 albedo = _AlbedaFactor * float3(_AlbedoColor.rgb);
                float3 ambient = _AmbientFactor * float3(_AmbientColor.rgb);
                float3 lighting = ambient;

                // Main light (usually directional)
                Light mainLight = GetMainLight();
                lighting += mainLight.color * (-_ContrastCorrection + max(0.05, dot(normal, mainLight.direction))) / (1 + _ContrastCorrection);

                // Additional lights
                int additionalLightsCount = GetAdditionalLightsCount();
                for (int j = 0; j < additionalLightsCount; j++)
                {
                    Light light = GetAdditionalLight(j, IN.positionWS);
                    lighting += light.color * (-_ContrastCorrection + max(0.05, dot(normal, light.direction))) / (1 + _ContrastCorrection);
                }

                float4 finalColorShaded = float4(albedo * lighting, _AlbedoColor.a);

                return finalColorShaded;    
            }
            ENDHLSL
        }
    }
}