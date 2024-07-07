using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.WebSockets;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Security.Cryptography.X509Certificates;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Chatbot.ChatbotModules;
using Chatbot.Modules;
using Discord;
using Discord.Commands;
using Discord.WebSocket;
using Microsoft.Extensions.DependencyInjection;
using SbsSW.SwiPlCs;
using SbsSW.SwiPlCs.Streams;

namespace Chatbot
{
    class Program
    {
        private static string BotToken = JsonDocument.Parse(File.ReadAllText("discord_key.json")).RootElement.GetProperty("your_key").GetString(); 
        static PrologStream prolog = new PrologStream();

        static void Main(string[] args)
        {
            string currentDir = System.IO.Directory.GetCurrentDirectory();
            Thread producingThread = new Thread(bothandler);
            producingThread.Start();
            string pathAlice = "Alice.pl";            

            if (!PlEngine.IsInitialized)
            {
                Environment.SetEnvironmentVariable("SWI_HOME_DIR", @"C:\Program Files\swipl\boot64.prc");
                String[] param = { "-q", pathAlice };
                PlEngine.Initialize(param);
                DelegateStreamReadFunction SreadDelegate = Sread;
                DelegateStreamWriteFunction SwriteDelegate = Swrite;
                PlEngine.SetStreamFunctionRead(SbsSW.SwiPlCs.Streams.PlStreamType.Input, SreadDelegate);
                PlEngine.SetStreamFunctionWrite(SbsSW.SwiPlCs.Streams.PlStreamType.Input, SwriteDelegate);

                while (true)
                {
                    PlQuery.PlCall("loop");
                }               
                PlEngine.PlCleanup(); //ending
            }
        }

        static private long Sread(IntPtr handle, System.IntPtr buffer, long buffersize)
        {
            string prologtemp = prolog.ReadToProlog();
            Debug.WriteLine(prologtemp);
            byte[] array = System.Text.Encoding.ASCII.GetBytes(prologtemp + "\n\0");
            
            if (buffersize > array.Length)
            {
                System.Runtime.InteropServices.Marshal.Copy(array, 0, buffer, array.Length);
                return array.Length;
            }
            return 0;
        }
        static private long Swrite(IntPtr handle, String buffer, long buffersize)
        {
            string s = buffer.Substring(0, (int)buffersize);
            Debug.WriteLine(s);
            prolog.WriteToDiscord(s);
            return buffersize;
        }

        static public void bothandler() 
        {
            RunBotAsync().GetAwaiter().GetResult();
        }
        private static DiscordSocketConfig _socketConfig;
        private static DiscordSocketClient _client;
        private static CommandService _commands;
        private static IServiceProvider _services;
        private static PrologStream prologStream = new PrologStream();
        public string CommandMessage { get; set; }
        public static async Task RunBotAsync()
        {
            _socketConfig = new DiscordSocketConfig()
            {
                GatewayIntents = GatewayIntents.AllUnprivileged |
                GatewayIntents.GuildMembers |
                GatewayIntents.MessageContent
            };
            _client = new DiscordSocketClient(_socketConfig);
            _commands = new CommandService();
            _services = new ServiceCollection()
                .AddSingleton<IPrologStream>(prologStream)
                .AddSingleton(_client)
                .AddSingleton(_commands)              
                .BuildServiceProvider();


            _client.Log += _client_log;
            await RegisterCommandAsync();
            await _client.LoginAsync(TokenType.Bot, BotToken);
            await _client.StartAsync();
            await Task.Delay(-1);

        }

        private static Task _client_log(LogMessage arg)
        {
            Console.WriteLine(arg);
            return Task.CompletedTask;
        }

        public static async Task RegisterCommandAsync()
        {
            _client.MessageReceived += HandleCommandAsync;
            var modules = await _commands.AddModulesAsync(Assembly.GetEntryAssembly(), _services);
            var submodels = modules.First().Submodules;
        }

        private static async Task HandleCommandAsync(SocketMessage arg)
        {
            Debug.WriteLine(arg.Content + " Length: " + arg.Content.Length);
            var message = arg as SocketUserMessage;
            var context = new SocketCommandContext(_client, message);
            if (message.Author.IsBot)
                return;
            Debug.WriteLine(message.Author.Id + " " + message.Author.Username);
            int argPos = 0;

            if (message.HasStringPrefix("!", ref argPos))
            {
                var result = await _commands.ExecuteAsync(context, argPos, _services);
                if (!result.IsSuccess) 
                    Console.WriteLine(result.ErrorReason + ". Message used was: " + message.Content);
                if (result.Error.Equals(CommandError.UnmetPrecondition))
                    await message.Channel.SendMessageAsync(result.ErrorReason);
            }
        }
    }
}
