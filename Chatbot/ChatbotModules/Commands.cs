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
        public Commands(IPrologStream prologStream)
        {
            this.prologStream = prologStream;
        }

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

        public string ChangeToList(string message)
        {
            //Ik wil mijn string aanpassen in tabs. tot 10.
            string[] values = message.Split("\t");
            string listValue = "";    
            if (values[0].Length > 3)
            {
                listValue = values[0].Substring(3);
            }
            listValue = listValue + "\n" + values[1] + "\t | \t" + values[2];
            for (int i = 3; i < values.Length - 1; i += 2)
            {
                listValue = listValue + "\n" + "1. " + values[i] + " | " + values[i + 1];
            }
            return listValue;
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

        [Command("ping")]
        public async Task Ping()
        {
            await ReplyAsync("Pong");
        }

        [Command("greet")]
        public async Task Greet()
        {
            await ReplyAsync("Welcome " + Context.User.Username);
        }

        [Command("help")]
        public async Task Help()
        {
            string movieQueries = @"
                Nederlandse vragen die gesteld kunnen worden: 
                ```1. Wie is star(A)?
2. Welke film heeft het langst geduurd om op te nemen?
3. In welke films speelde star(A)?
4. Wat is de kortste film met een waardering van star(A) of hoger?
5. Welke film heeft de hoogste score met de minste stemmen?
6. Hoeveel films heeft star(A) gemaakt?
7. Welke films zijn er tussen 2010 en nu uitgekomen waar star(A) voorkomt in de naam van de film?
8. Wat is het meest voorkomende genre?
9. In hoeveel films speelde star(A) in zijn eigen film mee?
10. Welke reggiseur heeft de meeste films met star(A) in de hoofdrol geregisseerd?
11. In welk jaar tussen 1990 en nu zijn de meeste films met de woord star(A) in de titel geproduceerd?
12. Welke acteur of actrice speelt het meest in de slechtst gewaardeerde films?
13. Zijn er films waarin star(A) wel speelde maar niet regiseerde?
14. Geef een overzicht van personen die meer dan 1 functie vervulden bij een film
15. Welke schrijvers spelen in hun eigen film en welke films zijn dat?
16. Welke acteur man of vrouw heeft de langste filmcarrière?
17. Welke acteur man of vrouw heeft de meeste dubbelrollen?
18. Welke films spelen in meer dan 1 land?```";

            string movieQueriesEnglish = @"
                English questions that are able to be asked:
                ```1. Who is star(A)?
2. Which movie took the longest to film?
3. In which movie played star(A)?
4. What is the shortest movie with a rating of star(A) or higher?
5. Which movie has the highest score with the least amount of votes?
6. How many movies did star(A) create?
7. Which movies between 2010 and now has the word star(A) in their movie?
8. What is the most common genre?
9. In how many movies did star(A) in their own created movie?
10. Which director heeft de meeste films met star(A) in de hoofdrol geregisseerd?
11. In which year between 1990 and where the most movies produced with the word star(A) in there title?
12. Which actor or actrice plays in the the worst rated movies?
13. Are there movies where star(A) plays in but does not produce?
14. Give an overview of persons who fulfilled more than 1 function at a movie
15. Which writers play in their own movie and what are those movies?
16. Which actor or actrice got the longest movie career?
17. Which actor or actrice got the most different rolls in a movie?
18. Which movies play in more then 1 country?```";

            await ReplyAsync(movieQueries);
            await ReplyAsync(movieQueriesEnglish);
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
            if (message.ToLower().StartsWith("startco"))
            {
                await ReplyAsync("Invalid command.");
                return;
            }
            var timeout = TimeSpan.FromSeconds(55);

            var task = Task.Run(() =>
            {
                prologStream.WriteToProlog(message);
                return prologStream.ReadToDiscord();
            });

            if (await Task.WhenAny(task, Task.Delay(timeout)) == task)
            {
                // Task completed within timeout
                string prologReply = await task;
                ITextChannel logChannel = Context.Client.GetChannel(ChatBotChannelID) as ITextChannel;
                if (prologReply.StartsWith("!18"))
                {
                    prologReply = ChangeToList(prologReply);
                }
                await logChannel.SendMessageAsync(prologReply);
            }
            else
            {
                // Task timed out
                await ReplyAsync("Kan ik niet op dit moment uitvoeren.");
            }

            //prologStream.WriteToProlog(message);
            //string prologReply = prologStream.ReadToDiscord();
            //ITextChannel logChannel = Context.Client.GetChannel(ChatBotChannelID) as ITextChannel;
            //await logChannel.SendMessageAsync(prologReply);
        }

        [Command("message")]
        public async Task message([Remainder] string message = null )
        {            
            if (message == null)
            {
                await ReplyAsync("Message not found.");
            }
            ITextChannel logChannel = Context.Client.GetChannel(ChatBotChannelID) as ITextChannel;
            await logChannel.SendMessageAsync(message);
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
