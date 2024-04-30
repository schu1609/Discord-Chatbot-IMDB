using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Dynamic;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using Chatbot.ChatbotModules;
using Discord;
using Discord.Commands;

namespace Chatbot.Modules
{ 
    public class Commands : ModuleBase<SocketCommandContext>
    {
        static ulong BanChannelID = 776460664285560882;
        static ulong ChatBotChannelID = 722409750523805767;
        static string prologSplitter = " A ";
        List<char> deniedSQLLetters = new List<char> { ';', '\\', '/', '$' };
        List<ulong> knownNewUsersId = new List<ulong>();
        List<ulong> allowedUserId = new List<ulong>();
        IPrologStream prologStream;
        public bool AllowerUser(string prologreply)
        {
            for (int i = 0; i < knownNewUsersId.Count; i++)
            {
                if (knownNewUsersId[i] == Context.User.Id)
                {
                    return false;
                }
            }
            prologStream.WriteToProlog("startcommand " + Context.User.Id);
            string prologReply = prologStream.ReadToDiscord().Trim();
            if (UInt64.TryParse(prologReply, out UInt64 replynumber))
            {
                if (replynumber == Context.User.Id)
                    return true;
            }
            return false;
        }
        public bool ValidLetters(string message)
        {
            for (int i = 0; i < deniedSQLLetters.Count; i++)
            {
                if (message.Contains(deniedSQLLetters[i]))
                {
                    return false;
                }
            }
            return true;
        }
        public string Adduser(string prologreply,string userName)
        {
            if (AllowerUser(prologreply))
                return string.Empty;
            knownNewUsersId.Remove(Context.User.Id);
            return "addinguser " + Context.User.Id + prologSplitter + userName;
        }
        public string ChangeUsername(string userName)
        {
            for (int i = 0; i < userName.Length; i++)
            {
                if (userName.Contains(deniedSQLLetters[i]))
                    return string.Empty;
            }
            return "updateuser" + userName + prologSplitter + Context.User.Id;
        }
        public Commands(IPrologStream prologStream) {
            this.prologStream = prologStream;
        }
        [Command("ping")]
        public async Task Ping()
        {
            await ReplyAsync("17 resultaten");
        }
        [Command("greet")]
        public async Task Greet()
        {
            await ReplyAsync("Welcome " + Context.User.Username);
        }
        [Command("start")]
        public async Task Start([Remainder] string message = null)
        {
            prologStream.WriteToProlog("startcommand " + Context.User.Id);
            string prologreply = prologStream.ReadToDiscord();
            if (AllowerUser(prologreply)) {
                await Greet();
                return;
            }
            knownNewUsersId.Add(Context.User.Id);
            if (message == null || message == string.Empty)
            {
                await ReplyAsync("please use !start \"here the username you wish to use while using this bot.\"");
                return;
            }
            else
            {
                if (!ValidLetters(message))
                {
                    await ReplyAsync("invalid username");
                    return;
                }
                prologStream.WriteToProlog(Adduser(prologreply, message));
            }
            ITextChannel logChannel = Context.Client.GetChannel(ChatBotChannelID) as ITextChannel;
            await logChannel.SendMessageAsync(message + " has been added to the database.");
        }

        [Command("addme")]
        public async Task AddMe(string userName)
        {
            prologStream.WriteToDiscord("addinguser " + userName + prologSplitter + Context.User.Id);
            knownNewUsersId.Remove(Context.User.Id);
            await ReplyAsync("user has been added.");
        }
        //hier komt eeen functie die prolog commando kan snappen en kan terug reageren.
        [Command("pm")]
        public async Task pm([Remainder] string message = null)
        {
            if (message == null || message == string.Empty)
            {
                await ReplyAsync("Message not found.");
                return;
            }
            if (!ValidLetters(message))
            {
                await ReplyAsync("Invalid command.");
                return;
            }
            if (message.ToLower().StartsWith("startco")) //fix ik zometeen volledig
            {
                await ReplyAsync("Invalid command.");
                return;
            }
            prologStream.WriteToProlog(message);
            string prologReply = prologStream.ReadToDiscord();
            if (!AllowerUser(prologReply)) //even denken hierover
            {
                if (!knownNewUsersId.Contains(Context.User.Id))
                    knownNewUsersId.Add(Context.User.Id);
                await ReplyAsync("Please use !start to get access to this bot.");
                return;
            }
            ITextChannel logChannel = Context.Client.GetChannel(ChatBotChannelID) as ITextChannel;
            await logChannel.SendMessageAsync(prologReply);
        }
        [Command("message")]
        public async Task message([Remainder] string message = null )
        {            
            if (message == null)
            {
                await ReplyAsync("Message not found.");
            }
            //Prolog.Message(message);
            ITextChannel logChannel = Context.Client.GetChannel(ChatBotChannelID) as ITextChannel;
            await logChannel.SendMessageAsync(message);
            //await ReplyAsync(message);
        }
        [Command("ban")]
        [RequireUserPermission(GuildPermission.BanMembers, ErrorMessage = "You don't have this kind of permission to ban people")]
        public async Task BanMember(IGuildUser user = null, [Remainder] string reason = null)
        {
            if (user == null){
                await ReplyAsync("Please specify a user!");
                return;
            }
            if (reason == null)
                reason = "not specified";

            await Context.Guild.AddBanAsync(user, 1, reason);

            var EmbedBuilder = new EmbedBuilder().WithDescription($":white_check_mark: {user.Mention} was banned\n **reason** {reason}")
                .WithFooter(footer =>
                {
                    footer
                    .WithText("User Ban log")
                    .WithIconUrl("https://i.imgur.com/XjNHpIy.png");
                });
            Embed embed = EmbedBuilder.Build();
            await ReplyAsync(embed : embed);

            ITextChannel logChannel = Context.Client.GetChannel(BanChannelID) as ITextChannel;
            var EmbedBuilderLog = new EmbedBuilder().WithDescription($"{user.Mention} was banned\n **reason** {reason}\n**Moderator** {Context.User.Mention}")
                .WithFooter(footer =>
                {
                    footer
                    .WithText("User Ban log")
                    .WithIconUrl("https://i.imgur.com/XjNHpIy.png");
                });
            Embed embedLog = EmbedBuilderLog.Build();
            await logChannel.SendMessageAsync(embed: embedLog);
        }
        [Command("unban")]
        [RequireUserPermission(GuildPermission.BanMembers, ErrorMessage = "You don't have this kind of permission to unban people")]
        public async Task UnBanMember(IGuildUser user = null, [Remainder] string reason = null)
        {
            if (user == null)
            {
                await ReplyAsync("Please specify a user!");
                return;
            }
            if (reason == null)
                reason = "not specified";

            await Context.Guild.RemoveBanAsync(user);

            var EmbedBuilder = new EmbedBuilder().WithDescription($":white_check_mark: {user.Mention} was unbanned\n **reason** {reason}")
                .WithFooter(footer =>
                {
                    footer
                    .WithText("User Ban log")
                    .WithIconUrl("https://i.imgur.com/XjNHpIy.png");
                });
            Embed embed = EmbedBuilder.Build();
            await ReplyAsync(embed: embed);

            ITextChannel logChannel = Context.Client.GetChannel(BanChannelID) as ITextChannel;
            var EmbedBuilderLog = new EmbedBuilder().WithDescription($"{user.Mention} was unbanned\n **reason** {reason}\n**Moderator** {Context.User.Mention}")
                .WithFooter(footer =>
                {
                    footer
                    .WithText("User Ban log")
                    .WithIconUrl("https://i.imgur.com/XjNHpIy.png");
                });
            Embed embedLog = EmbedBuilderLog.Build();
            await logChannel.SendMessageAsync(embed: embedLog);
        }

        [Command("kick")]
        [RequireUserPermission(GuildPermission.BanMembers, ErrorMessage = "You don't have this kind of permission to kick people")]
        public async Task KickMember(IGuildUser user = null, [Remainder] string reason = null)
        {
            if (user == null)
            {
                await ReplyAsync("Please specify a user!");
                return;
            }
            if (reason == null)
                reason = "not specified";

            await user.KickAsync(reason);

            var EmbedBuilder = new EmbedBuilder().WithDescription($":white_check_mark: {user.Mention} was kicked\n **reason** {reason}")
                .WithFooter(footer =>
                {
                    footer
                    .WithText("User Ban log")
                    .WithIconUrl("https://i.imgur.com/XjNHpIy.png");
                });
            Embed embed = EmbedBuilder.Build();
            await ReplyAsync(embed: embed);
        }

    }
}
