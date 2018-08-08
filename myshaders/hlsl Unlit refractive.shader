Shader "Glass/Unlit refractive"
{
	Properties
	{
		_Color ("Texture Tint",Color ) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}

	  	_Normal ("Normal" , 2D) = "blue" {}
	  	normalPo("Normal Power",Range(0,1))= 0
	  	_ColorRed ("Refraction Tint",Color ) = (1,1,1,1)
	  	_IOR("IOR",Range(1.0,-1.0)) = 0
	  	roughness("roughness",Range(0,5)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float2 Nuv : TEXCOORD1;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 Nuv : TEXCOORD1;
				UNITY_FOG_COORDS(5)
				float4 vertex : SV_POSITION;
				float3 normalDir : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
			};

			sampler2D _MainTex;
			sampler2D _Normal;
			float4 _MainTex_ST;
			float4 _Normal_ST;
			float _IOR;
 		 	float roughness;
 		 	float normalPo;
 		 	fixed4 _Color;
 		 	fixed4 _ColorRed;

 		 	float3 blendNormals(float3 n1, float3 n2){
				 return normalize(float3(n1.rg + n2.rg, n1.b * n2.b));
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				v.Nuv = v.uv;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.Nuv = TRANSFORM_TEX(v.Nuv, _Normal);
				UNITY_TRANSFER_FOG(o,o.vertex);

				float4x4 modelMatrix = unity_ObjectToWorld;
            	float4x4 modelMatrixInverse = unity_WorldToObject; 
 
	            o.viewDir = mul(modelMatrix, v.vertex).xyz - _WorldSpaceCameraPos;

	            o.normalDir = normalize( mul(float4(v.normal, 0.0), modelMatrixInverse).xyz);
	            //o.normalDir = v.normal;
	            o.vertex = UnityObjectToClipPos(v.vertex);


				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 bump = UnpackNormal(tex2D(_Normal, i.Nuv));

				bump = lerp(half3(0,0,1) , bump ,normalPo);
				i.normalDir.xyz = blendNormals(i.normalDir.xyz,bump);
	            float3 refractedDir = refract(normalize(i.viewDir), normalize(i.normalDir), _IOR);

	            float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, refractedDir, roughness );
	            envSample.rgb *= _ColorRed.xyz;

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				col *= _Color;
				col.rgb = lerp (float3(1,1,1) , col.rgb , col.a);
				col *= envSample;
				//col.rgb = bump;
				//col.rgb = i.normalDir;
				return col;
			}
			ENDCG
		}
	}
}
