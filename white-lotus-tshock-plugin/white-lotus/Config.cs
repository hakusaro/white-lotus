using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json;

namespace white_lotus
{
	class Config
	{
		public string RestToken { get; set; }
		public string ServerId { get; set; }
		public int GlobalBansTriggerCount { get; set; }
		public bool NotifyGlobalBans { get; set; }

		public void Write(string path)
		{
			using(var writer = new StreamWriter(path))
			{
				var text = JsonConvert.SerializeObject(this, Formatting.Indented);
				writer.Write(text);
			}
		}

		public static Config Read(string path)
		{
			using(var reader = new StreamReader(path))
			{
				var text = reader.ReadToEnd();
				return JsonConvert.DeserializeObject<Config>(text);
			}
		}
	}
}
